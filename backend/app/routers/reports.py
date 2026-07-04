"""Router: Báo cáo & thống kê tổng hợp cho toàn hệ thống."""
from datetime import date, datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/reports", tags=["Báo cáo thống kê"])


@router.get("/dashboard", response_model=schemas.DashboardSummary)
def dashboard_summary(
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """Tổng quan nhanh cho trang chủ dashboard."""
    today = date.today()
    month_start = today.replace(day=1)

    total_members = db.query(func.count(models.Member.id)).scalar()
    active_members = db.query(func.count(models.Member.id)).filter(
        models.Member.status == models.StatusEnum.active
    ).scalar()
    total_trainers = db.query(func.count(models.Trainer.id)).scalar()
    total_staff = db.query(func.count(models.Staff.id)).scalar()
    active_subscriptions = db.query(func.count(models.MembershipSubscription.id)).filter(
        models.MembershipSubscription.status == models.SubscriptionStatusEnum.active,
        models.MembershipSubscription.end_date >= today,
    ).scalar()
    revenue_this_month = db.query(func.coalesce(func.sum(models.MembershipSubscription.price_paid), 0.0)).filter(
        models.MembershipSubscription.start_date >= month_start,
        models.MembershipSubscription.start_date <= today,
    ).scalar()
    new_members_this_month = db.query(func.count(models.Member.id)).filter(
        models.Member.join_date >= month_start,
        models.Member.join_date <= today,
    ).scalar()
    upcoming_pt_sessions = db.query(func.count(models.PTSchedule.id)).filter(
        models.PTSchedule.date >= today,
        models.PTSchedule.status == models.PTScheduleStatusEnum.scheduled,
    ).scalar()
    upcoming_class_sessions = db.query(func.count(models.ClassSchedule.id)).filter(
        models.ClassSchedule.date >= today,
    ).scalar()

    return schemas.DashboardSummary(
        total_members=total_members or 0,
        active_members=active_members or 0,
        total_trainers=total_trainers or 0,
        total_staff=total_staff or 0,
        active_subscriptions=active_subscriptions or 0,
        revenue_this_month=float(revenue_this_month or 0),
        new_members_this_month=new_members_this_month or 0,
        upcoming_pt_sessions=upcoming_pt_sessions or 0,
        upcoming_class_sessions=upcoming_class_sessions or 0,
    )


@router.get("/revenue", response_model=List[schemas.RevenuePoint])
def revenue_report(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    group_by: str = Query("month", pattern="^(day|month|year)$"),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """Doanh thu từ các gói tập đã đăng ký, gom theo ngày/tháng/năm."""
    query = db.query(models.MembershipSubscription)
    if date_from:
        query = query.filter(models.MembershipSubscription.start_date >= date_from)
    if date_to:
        query = query.filter(models.MembershipSubscription.start_date <= date_to)
    rows = query.all()

    buckets = {}
    for row in rows:
        d = row.start_date
        if group_by == "day":
            key = d.strftime("%Y-%m-%d")
        elif group_by == "year":
            key = d.strftime("%Y")
        else:
            key = d.strftime("%Y-%m")
        bucket = buckets.setdefault(key, {"revenue": 0.0, "count": 0})
        bucket["revenue"] += row.price_paid
        bucket["count"] += 1

    return [
        schemas.RevenuePoint(period=key, revenue=v["revenue"], subscription_count=v["count"])
        for key, v in sorted(buckets.items())
    ]


@router.get("/package-sales", response_model=List[schemas.PackageSalesPoint])
def package_sales_report(
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """Thống kê số lượt bán và doanh thu theo từng gói tập."""
    rows = (
        db.query(
            models.Package.id,
            models.Package.name,
            func.count(models.MembershipSubscription.id).label("sold_count"),
            func.coalesce(func.sum(models.MembershipSubscription.price_paid), 0.0).label("total_revenue"),
        )
        .outerjoin(models.MembershipSubscription, models.MembershipSubscription.package_id == models.Package.id)
        .group_by(models.Package.id, models.Package.name)
        .order_by(func.count(models.MembershipSubscription.id).desc())
        .all()
    )
    return [
        schemas.PackageSalesPoint(
            package_id=r.id, package_name=r.name, sold_count=r.sold_count, total_revenue=float(r.total_revenue)
        )
        for r in rows
    ]


@router.get("/trainer-sessions", response_model=List[schemas.TrainerSessionPoint])
def trainer_sessions_report(
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """Số buổi PT cá nhân và số lớp nhóm phụ trách theo từng huấn luyện viên."""
    trainers = db.query(models.Trainer).all()
    result = []
    for t in trainers:
        pt_count = db.query(func.count(models.PTSchedule.id)).filter(
            models.PTSchedule.trainer_id == t.id,
            models.PTSchedule.status != models.PTScheduleStatusEnum.cancelled,
        ).scalar()
        class_count = db.query(func.count(models.GroupClass.id)).filter(
            models.GroupClass.trainer_id == t.id
        ).scalar()
        result.append(
            schemas.TrainerSessionPoint(
                trainer_id=t.id,
                trainer_name=t.full_name,
                pt_session_count=pt_count or 0,
                group_class_count=class_count or 0,
            )
        )
    return result


@router.get("/class-attendance", response_model=List[schemas.ClassAttendancePoint])
def class_attendance_report(
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """Tỉ lệ điểm danh theo từng lớp học nhóm."""
    classes = db.query(models.GroupClass).all()
    result = []
    for c in classes:
        total_sessions = len(c.schedules)
        total_registrations = 0
        total_attended = 0
        for s in c.schedules:
            for r in s.registrations:
                if r.status != models.RegistrationStatusEnum.cancelled:
                    total_registrations += 1
                if r.status == models.RegistrationStatusEnum.attended:
                    total_attended += 1
        rate = (total_attended / total_registrations * 100) if total_registrations else 0.0
        result.append(
            schemas.ClassAttendancePoint(
                class_id=c.id,
                class_name=c.name,
                total_sessions=total_sessions,
                total_registrations=total_registrations,
                total_attended=total_attended,
                attendance_rate=round(rate, 2),
            )
        )
    return result


@router.get("/new-members", response_model=List[schemas.RevenuePoint])
def new_members_report(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    group_by: str = Query("month", pattern="^(day|month|year)$"),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    """
    Số thành viên mới theo thời gian.
    (Tái dùng schema RevenuePoint: field 'revenue' = 0, 'subscription_count' = số thành viên mới)
    """
    query = db.query(models.Member)
    if date_from:
        query = query.filter(models.Member.join_date >= date_from)
    if date_to:
        query = query.filter(models.Member.join_date <= date_to)
    rows = query.all()

    buckets = {}
    for m in rows:
        d = m.join_date
        if group_by == "day":
            key = d.strftime("%Y-%m-%d")
        elif group_by == "year":
            key = d.strftime("%Y")
        else:
            key = d.strftime("%Y-%m")
        buckets[key] = buckets.get(key, 0) + 1

    return [
        schemas.RevenuePoint(period=key, revenue=0.0, subscription_count=count)
        for key, count in sorted(buckets.items())
    ]

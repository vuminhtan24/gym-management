"""Router: Quản lý gói tập (Package) và việc đăng ký gói (Subscription)."""
from datetime import timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/packages", tags=["Quản lý gói tập"])
sub_router = APIRouter(prefix="/subscriptions", tags=["Đăng ký gói tập"])


# ================= PACKAGE CRUD =================

@router.post("", response_model=schemas.PackageOut, status_code=status.HTTP_201_CREATED)
def create_package(
    payload: schemas.PackageCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    package = models.Package(**payload.model_dump())
    db.add(package)
    db.commit()
    db.refresh(package)
    return package


@router.get("", response_model=List[schemas.PackageOut])
def list_packages(
    only_active: bool = False,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.Package)
    if only_active:
        query = query.filter(models.Package.is_active == models.StatusEnum.active)
    return query.order_by(models.Package.id).all()


@router.get("/{package_id}", response_model=schemas.PackageOut)
def get_package(
    package_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    package = db.query(models.Package).filter(models.Package.id == package_id).first()
    if not package:
        raise HTTPException(status_code=404, detail="Không tìm thấy gói tập")
    return package


@router.put("/{package_id}", response_model=schemas.PackageOut)
def update_package(
    package_id: int,
    payload: schemas.PackageUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    package = db.query(models.Package).filter(models.Package.id == package_id).first()
    if not package:
        raise HTTPException(status_code=404, detail="Không tìm thấy gói tập")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(package, field, value)
    db.commit()
    db.refresh(package)
    return package


@router.delete("/{package_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_package(
    package_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    package = db.query(models.Package).filter(models.Package.id == package_id).first()
    if not package:
        raise HTTPException(status_code=404, detail="Không tìm thấy gói tập")
    db.delete(package)
    db.commit()
    return None


# ================= SUBSCRIPTION (đăng ký gói) =================

@sub_router.post("", response_model=schemas.SubscriptionOut, status_code=status.HTTP_201_CREATED)
def create_subscription(
    payload: schemas.SubscriptionCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    member = db.query(models.Member).filter(models.Member.id == payload.member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")

    package = db.query(models.Package).filter(models.Package.id == payload.package_id).first()
    if not package:
        raise HTTPException(status_code=404, detail="Không tìm thấy gói tập")

    end_date = payload.start_date + timedelta(days=package.duration_days)
    subscription = models.MembershipSubscription(
        member_id=payload.member_id,
        package_id=payload.package_id,
        start_date=payload.start_date,
        end_date=end_date,
        price_paid=payload.price_paid if payload.price_paid is not None else package.price,
        status=models.SubscriptionStatusEnum.active,
    )
    db.add(subscription)
    db.commit()
    db.refresh(subscription)
    return subscription


@sub_router.get("", response_model=List[schemas.SubscriptionOut])
def list_subscriptions(
    member_id: Optional[int] = None,
    status_filter: Optional[models.SubscriptionStatusEnum] = Query(None, alias="status"),
    skip: int = 0,
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.MembershipSubscription)
    if member_id:
        query = query.filter(models.MembershipSubscription.member_id == member_id)
    if status_filter:
        query = query.filter(models.MembershipSubscription.status == status_filter)
    return query.order_by(models.MembershipSubscription.id.desc()).offset(skip).limit(limit).all()


@sub_router.put("/{subscription_id}", response_model=schemas.SubscriptionOut)
def update_subscription(
    subscription_id: int,
    payload: schemas.SubscriptionUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    sub = db.query(models.MembershipSubscription).filter(
        models.MembershipSubscription.id == subscription_id
    ).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Không tìm thấy đăng ký gói")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(sub, field, value)
    db.commit()
    db.refresh(sub)
    return sub


@sub_router.delete("/{subscription_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subscription(
    subscription_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    sub = db.query(models.MembershipSubscription).filter(
        models.MembershipSubscription.id == subscription_id
    ).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Không tìm thấy đăng ký gói")
    db.delete(sub)
    db.commit()
    return None

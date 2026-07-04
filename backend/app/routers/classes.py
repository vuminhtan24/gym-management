"""Router: Quản lý lớp học nhóm (GroupClass), buổi học (ClassSchedule) và đăng ký (ClassRegistration)."""
from datetime import date as date_type
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/classes", tags=["Quản lý lớp học nhóm"])


# ================= GROUP CLASS =================

@router.post("", response_model=schemas.GroupClassOut, status_code=status.HTTP_201_CREATED)
def create_group_class(
    payload: schemas.GroupClassCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    if payload.trainer_id and not db.query(models.Trainer).filter(models.Trainer.id == payload.trainer_id).first():
        raise HTTPException(status_code=404, detail="Không tìm thấy huấn luyện viên")
    group_class = models.GroupClass(**payload.model_dump())
    db.add(group_class)
    db.commit()
    db.refresh(group_class)
    return group_class


@router.get("", response_model=List[schemas.GroupClassOut])
def list_group_classes(
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    return db.query(models.GroupClass).order_by(models.GroupClass.id).all()


@router.get("/{class_id}", response_model=schemas.GroupClassOut)
def get_group_class(
    class_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    group_class = db.query(models.GroupClass).filter(models.GroupClass.id == class_id).first()
    if not group_class:
        raise HTTPException(status_code=404, detail="Không tìm thấy lớp học")
    return group_class


@router.put("/{class_id}", response_model=schemas.GroupClassOut)
def update_group_class(
    class_id: int,
    payload: schemas.GroupClassUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    group_class = db.query(models.GroupClass).filter(models.GroupClass.id == class_id).first()
    if not group_class:
        raise HTTPException(status_code=404, detail="Không tìm thấy lớp học")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(group_class, field, value)
    db.commit()
    db.refresh(group_class)
    return group_class


@router.delete("/{class_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_group_class(
    class_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    group_class = db.query(models.GroupClass).filter(models.GroupClass.id == class_id).first()
    if not group_class:
        raise HTTPException(status_code=404, detail="Không tìm thấy lớp học")
    db.delete(group_class)
    db.commit()
    return None


# ================= CLASS SCHEDULE (buổi học cụ thể) =================

@router.post("/schedules", response_model=schemas.ClassScheduleOut, status_code=status.HTTP_201_CREATED)
def create_class_schedule(
    payload: schemas.ClassScheduleCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    if not db.query(models.GroupClass).filter(models.GroupClass.id == payload.class_id).first():
        raise HTTPException(status_code=404, detail="Không tìm thấy lớp học")
    if payload.start_time >= payload.end_time:
        raise HTTPException(status_code=400, detail="Giờ bắt đầu phải trước giờ kết thúc")
    schedule = models.ClassSchedule(**payload.model_dump())
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.get("/schedules", response_model=List[schemas.ClassScheduleOut])
def list_class_schedules(
    class_id: Optional[int] = None,
    date_from: Optional[date_type] = None,
    date_to: Optional[date_type] = None,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.ClassSchedule)
    if class_id:
        query = query.filter(models.ClassSchedule.class_id == class_id)
    if date_from:
        query = query.filter(models.ClassSchedule.date >= date_from)
    if date_to:
        query = query.filter(models.ClassSchedule.date <= date_to)
    schedules = query.order_by(models.ClassSchedule.date, models.ClassSchedule.start_time).all()

    result = []
    for s in schedules:
        out = schemas.ClassScheduleOut.model_validate(s)
        out.registered_count = len(
            [r for r in s.registrations if r.status != models.RegistrationStatusEnum.cancelled]
        )
        result.append(out)
    return result


@router.delete("/schedules/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_class_schedule(
    schedule_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    schedule = db.query(models.ClassSchedule).filter(models.ClassSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Không tìm thấy buổi học")
    db.delete(schedule)
    db.commit()
    return None


# ================= CLASS REGISTRATION (đăng ký học) =================

@router.post("/registrations", response_model=schemas.ClassRegistrationOut, status_code=status.HTTP_201_CREATED)
def register_class(
    payload: schemas.ClassRegistrationCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    schedule = db.query(models.ClassSchedule).filter(
        models.ClassSchedule.id == payload.class_schedule_id
    ).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Không tìm thấy buổi học")
    if not db.query(models.Member).filter(models.Member.id == payload.member_id).first():
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")

    existing = db.query(models.ClassRegistration).filter(
        models.ClassRegistration.class_schedule_id == payload.class_schedule_id,
        models.ClassRegistration.member_id == payload.member_id,
        models.ClassRegistration.status != models.RegistrationStatusEnum.cancelled,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Thành viên đã đăng ký buổi học này")

    active_count = len(
        [r for r in schedule.registrations if r.status != models.RegistrationStatusEnum.cancelled]
    )
    if active_count >= schedule.group_class.max_participants:
        raise HTTPException(status_code=400, detail="Lớp học đã đủ số lượng tối đa")

    registration = models.ClassRegistration(**payload.model_dump())
    db.add(registration)
    db.commit()
    db.refresh(registration)
    return registration


@router.get("/registrations", response_model=List[schemas.ClassRegistrationOut])
def list_registrations(
    class_schedule_id: Optional[int] = None,
    member_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.ClassRegistration)
    if class_schedule_id:
        query = query.filter(models.ClassRegistration.class_schedule_id == class_schedule_id)
    if member_id:
        query = query.filter(models.ClassRegistration.member_id == member_id)
    return query.order_by(models.ClassRegistration.id.desc()).all()


@router.put("/registrations/{registration_id}", response_model=schemas.ClassRegistrationOut)
def update_registration_status(
    registration_id: int,
    payload: schemas.ClassRegistrationUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    registration = db.query(models.ClassRegistration).filter(
        models.ClassRegistration.id == registration_id
    ).first()
    if not registration:
        raise HTTPException(status_code=404, detail="Không tìm thấy đăng ký")
    registration.status = payload.status
    db.commit()
    db.refresh(registration)
    return registration

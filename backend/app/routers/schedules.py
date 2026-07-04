"""Router: Quản lý lịch tập cá nhân (Personal Training) giữa thành viên và HLV."""
from datetime import date as date_type
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/pt-schedules", tags=["Quản lý lịch tập cá nhân"])


def _check_trainer_conflict(db: Session, trainer_id: int, date_: date_type, start_time, end_time, exclude_id: Optional[int] = None):
    """Kiểm tra HLV có bị trùng giờ dạy trong ngày không."""
    query = db.query(models.PTSchedule).filter(
        models.PTSchedule.trainer_id == trainer_id,
        models.PTSchedule.date == date_,
        models.PTSchedule.status != models.PTScheduleStatusEnum.cancelled,
        models.PTSchedule.start_time < end_time,
        models.PTSchedule.end_time > start_time,
    )
    if exclude_id:
        query = query.filter(models.PTSchedule.id != exclude_id)
    return query.first() is not None


@router.post("", response_model=schemas.PTScheduleOut, status_code=status.HTTP_201_CREATED)
def create_pt_schedule(
    payload: schemas.PTScheduleCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    if not db.query(models.Member).filter(models.Member.id == payload.member_id).first():
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")
    if not db.query(models.Trainer).filter(models.Trainer.id == payload.trainer_id).first():
        raise HTTPException(status_code=404, detail="Không tìm thấy huấn luyện viên")
    if payload.start_time >= payload.end_time:
        raise HTTPException(status_code=400, detail="Giờ bắt đầu phải trước giờ kết thúc")
    if _check_trainer_conflict(db, payload.trainer_id, payload.date, payload.start_time, payload.end_time):
        raise HTTPException(status_code=400, detail="Huấn luyện viên đã có lịch trùng giờ này")

    schedule = models.PTSchedule(**payload.model_dump())
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.get("", response_model=List[schemas.PTScheduleOut])
def list_pt_schedules(
    member_id: Optional[int] = None,
    trainer_id: Optional[int] = None,
    date_from: Optional[date_type] = None,
    date_to: Optional[date_type] = None,
    status_filter: Optional[models.PTScheduleStatusEnum] = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.PTSchedule)
    if member_id:
        query = query.filter(models.PTSchedule.member_id == member_id)
    if trainer_id:
        query = query.filter(models.PTSchedule.trainer_id == trainer_id)
    if date_from:
        query = query.filter(models.PTSchedule.date >= date_from)
    if date_to:
        query = query.filter(models.PTSchedule.date <= date_to)
    if status_filter:
        query = query.filter(models.PTSchedule.status == status_filter)
    return query.order_by(models.PTSchedule.date, models.PTSchedule.start_time).all()


@router.put("/{schedule_id}", response_model=schemas.PTScheduleOut)
def update_pt_schedule(
    schedule_id: int,
    payload: schemas.PTScheduleUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    schedule = db.query(models.PTSchedule).filter(models.PTSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Không tìm thấy lịch tập")

    update_data = payload.model_dump(exclude_unset=True)
    new_date = update_data.get("date", schedule.date)
    new_start = update_data.get("start_time", schedule.start_time)
    new_end = update_data.get("end_time", schedule.end_time)
    if new_start >= new_end:
        raise HTTPException(status_code=400, detail="Giờ bắt đầu phải trước giờ kết thúc")
    if _check_trainer_conflict(db, schedule.trainer_id, new_date, new_start, new_end, exclude_id=schedule_id):
        raise HTTPException(status_code=400, detail="Huấn luyện viên đã có lịch trùng giờ này")

    for field, value in update_data.items():
        setattr(schedule, field, value)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.delete("/{schedule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_pt_schedule(
    schedule_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    schedule = db.query(models.PTSchedule).filter(models.PTSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Không tìm thấy lịch tập")
    db.delete(schedule)
    db.commit()
    return None

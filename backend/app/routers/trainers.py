"""Router: Quản lý huấn luyện viên (Trainer)."""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/trainers", tags=["Quản lý huấn luyện viên"])


@router.post("", response_model=schemas.TrainerOut, status_code=status.HTTP_201_CREATED)
def create_trainer(
    payload: schemas.TrainerCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    existing = db.query(models.Trainer).filter(models.Trainer.phone == payload.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Số điện thoại đã tồn tại")
    trainer = models.Trainer(**payload.model_dump())
    db.add(trainer)
    db.commit()
    db.refresh(trainer)
    return trainer


@router.get("", response_model=List[schemas.TrainerOut])
def list_trainers(
    search: Optional[str] = None,
    status_filter: Optional[models.StatusEnum] = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.Trainer)
    if search:
        query = query.filter(models.Trainer.full_name.ilike(f"%{search}%"))
    if status_filter:
        query = query.filter(models.Trainer.status == status_filter)
    return query.order_by(models.Trainer.id).all()


@router.get("/{trainer_id}", response_model=schemas.TrainerOut)
def get_trainer(
    trainer_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    trainer = db.query(models.Trainer).filter(models.Trainer.id == trainer_id).first()
    if not trainer:
        raise HTTPException(status_code=404, detail="Không tìm thấy huấn luyện viên")
    return trainer


@router.put("/{trainer_id}", response_model=schemas.TrainerOut)
def update_trainer(
    trainer_id: int,
    payload: schemas.TrainerUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    trainer = db.query(models.Trainer).filter(models.Trainer.id == trainer_id).first()
    if not trainer:
        raise HTTPException(status_code=404, detail="Không tìm thấy huấn luyện viên")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(trainer, field, value)
    db.commit()
    db.refresh(trainer)
    return trainer


@router.delete("/{trainer_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trainer(
    trainer_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    trainer = db.query(models.Trainer).filter(models.Trainer.id == trainer_id).first()
    if not trainer:
        raise HTTPException(status_code=404, detail="Không tìm thấy huấn luyện viên")
    db.delete(trainer)
    db.commit()
    return None

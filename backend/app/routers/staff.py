"""Router: Quản lý nhân viên (Staff). Chỉ admin/manager được thêm/sửa/xóa."""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/staff", tags=["Quản lý nhân viên"])


@router.post("", response_model=schemas.StaffOut, status_code=status.HTTP_201_CREATED)
def create_staff(
    payload: schemas.StaffCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    existing = db.query(models.Staff).filter(
        (models.Staff.username == payload.username) | (models.Staff.phone == payload.phone)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username hoặc số điện thoại đã tồn tại")

    data = payload.model_dump(exclude={"password"})
    staff = models.Staff(**data, hashed_password=auth.hash_password(payload.password))
    db.add(staff)
    db.commit()
    db.refresh(staff)
    return staff


@router.get("", response_model=List[schemas.StaffOut])
def list_staff(
    search: Optional[str] = None,
    role: Optional[models.StaffRoleEnum] = None,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    query = db.query(models.Staff)
    if search:
        query = query.filter(models.Staff.full_name.ilike(f"%{search}%"))
    if role:
        query = query.filter(models.Staff.role == role)
    return query.order_by(models.Staff.id).all()


@router.get("/{staff_id}", response_model=schemas.StaffOut)
def get_staff(
    staff_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    staff = db.query(models.Staff).filter(models.Staff.id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhân viên")
    return staff


@router.put("/{staff_id}", response_model=schemas.StaffOut)
def update_staff(
    staff_id: int,
    payload: schemas.StaffUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    staff = db.query(models.Staff).filter(models.Staff.id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhân viên")

    update_data = payload.model_dump(exclude_unset=True, exclude={"password"})
    for field, value in update_data.items():
        setattr(staff, field, value)
    if payload.password:
        staff.hashed_password = auth.hash_password(payload.password)

    db.commit()
    db.refresh(staff)
    return staff


@router.delete("/{staff_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_staff(
    staff_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin)),
):
    if staff_id == current_staff.id:
        raise HTTPException(status_code=400, detail="Không thể tự xóa chính mình")
    staff = db.query(models.Staff).filter(models.Staff.id == staff_id).first()
    if not staff:
        raise HTTPException(status_code=404, detail="Không tìm thấy nhân viên")
    db.delete(staff)
    db.commit()
    return None

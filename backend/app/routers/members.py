"""Router: Quản lý thành viên (Member)."""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/members", tags=["Quản lý thành viên"])


@router.post("", response_model=schemas.MemberOut, status_code=status.HTTP_201_CREATED)
def create_member(
    payload: schemas.MemberCreate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    existing = db.query(models.Member).filter(models.Member.phone == payload.phone).first()
    if existing:
        raise HTTPException(status_code=400, detail="Số điện thoại đã được đăng ký")

    member = models.Member(**payload.model_dump())
    db.add(member)
    db.commit()
    db.refresh(member)
    return member


@router.get("", response_model=List[schemas.MemberOut])
def list_members(
    skip: int = 0,
    limit: int = Query(50, le=200),
    search: Optional[str] = Query(None, description="Tìm theo tên, sđt hoặc email"),
    status_filter: Optional[models.StatusEnum] = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    query = db.query(models.Member)
    if search:
        query = query.filter(
            or_(
                models.Member.full_name.ilike(f"%{search}%"),
                models.Member.phone.ilike(f"%{search}%"),
                models.Member.email.ilike(f"%{search}%"),
            )
        )
    if status_filter:
        query = query.filter(models.Member.status == status_filter)
    return query.order_by(models.Member.id.desc()).offset(skip).limit(limit).all()


@router.get("/{member_id}", response_model=schemas.MemberOut)
def get_member(
    member_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")
    return member


@router.put("/{member_id}", response_model=schemas.MemberOut)
def update_member(
    member_id: int,
    payload: schemas.MemberUpdate,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(member, field, value)

    db.commit()
    db.refresh(member)
    return member


@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_member(
    member_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.require_roles(models.StaffRoleEnum.admin, models.StaffRoleEnum.manager)),
):
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")
    db.delete(member)
    db.commit()
    return None


# ---------- Đăng ký gói tập cho thành viên ----------

@router.get("/{member_id}/subscriptions", response_model=List[schemas.SubscriptionOut])
def get_member_subscriptions(
    member_id: int,
    db: Session = Depends(get_db),
    current_staff: models.Staff = Depends(auth.get_current_staff),
):
    member = db.query(models.Member).filter(models.Member.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Không tìm thấy thành viên")
    return member.subscriptions

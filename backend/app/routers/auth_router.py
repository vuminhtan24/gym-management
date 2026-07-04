"""Router: đăng nhập hệ thống cho nhân viên."""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/auth", tags=["Đăng nhập"])


@router.post("/login", response_model=schemas.TokenResponse)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Đăng nhập bằng username/password (dùng chuẩn OAuth2 form, tương thích
    nút "Authorize" trên Swagger UI /docs).
    """
    staff = db.query(models.Staff).filter(models.Staff.username == form_data.username).first()
    if not staff or not auth.verify_password(form_data.password, staff.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sai tên đăng nhập hoặc mật khẩu",
        )
    if staff.status != models.StatusEnum.active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tài khoản đã bị khóa")

    access_token = auth.create_access_token(data={"sub": str(staff.id)})
    return schemas.TokenResponse(access_token=access_token, staff=staff)


@router.get("/me", response_model=schemas.StaffOut)
def get_me(current_staff: models.Staff = Depends(auth.get_current_staff)):
    """Lấy thông tin nhân viên đang đăng nhập."""
    return current_staff

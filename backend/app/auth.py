"""
Xử lý xác thực: hash password, tạo/giải mã JWT, dependency kiểm tra
nhân viên đăng nhập và phân quyền theo role.

Lưu ý bảo mật: đổi SECRET_KEY bằng biến môi trường khi deploy thật,
không dùng giá trị mặc định trong production.
"""
import os
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from . import models
from .database import get_db

SECRET_KEY = os.getenv("SECRET_KEY", "change-this-secret-key-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "480"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_staff(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> models.Staff:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Không thể xác thực thông tin đăng nhập",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        staff_id: Optional[str] = payload.get("sub")
        if staff_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    staff = db.query(models.Staff).filter(models.Staff.id == int(staff_id)).first()
    if staff is None or staff.status != models.StatusEnum.active:
        raise credentials_exception
    return staff


def require_roles(*allowed_roles: models.StaffRoleEnum):
    """Dependency factory: chỉ cho phép các role được liệt kê truy cập endpoint."""

    def checker(current_staff: models.Staff = Depends(get_current_staff)) -> models.Staff:
        if current_staff.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền thực hiện hành động này",
            )
        return current_staff

    return checker

"""
Pydantic schemas dùng cho validate request và định dạng response.
Quy ước đặt tên: XxxCreate (tạo mới), XxxUpdate (cập nhật, field optional),
XxxOut (trả về cho client).
"""
from datetime import date, time, datetime
from typing import Optional, List

from pydantic import BaseModel, EmailStr, ConfigDict, Field

from .models import (
    GenderEnum, StatusEnum, SubscriptionStatusEnum,
    PTScheduleStatusEnum, RegistrationStatusEnum, StaffRoleEnum,
)


# ================= MEMBER =================

class MemberBase(BaseModel):
    full_name: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=20)
    email: Optional[EmailStr] = None
    gender: GenderEnum = GenderEnum.other
    dob: Optional[date] = None
    address: Optional[str] = None
    note: Optional[str] = None


class MemberCreate(MemberBase):
    pass


class MemberUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    gender: Optional[GenderEnum] = None
    dob: Optional[date] = None
    address: Optional[str] = None
    note: Optional[str] = None
    status: Optional[StatusEnum] = None


class MemberOut(MemberBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    join_date: date
    status: StatusEnum


# ================= PACKAGE =================

class PackageBase(BaseModel):
    name: str = Field(..., max_length=100)
    duration_days: int = Field(..., gt=0)
    price: float = Field(..., ge=0)
    description: Optional[str] = None


class PackageCreate(PackageBase):
    pass


class PackageUpdate(BaseModel):
    name: Optional[str] = None
    duration_days: Optional[int] = None
    price: Optional[float] = None
    description: Optional[str] = None
    is_active: Optional[StatusEnum] = None


class PackageOut(PackageBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    is_active: StatusEnum


# ================= SUBSCRIPTION (đăng ký gói) =================

class SubscriptionCreate(BaseModel):
    member_id: int
    package_id: int
    start_date: date
    price_paid: Optional[float] = None  # nếu None sẽ lấy theo giá gói


class SubscriptionUpdate(BaseModel):
    status: Optional[SubscriptionStatusEnum] = None
    end_date: Optional[date] = None


class SubscriptionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    member_id: int
    package_id: int
    start_date: date
    end_date: date
    price_paid: float
    status: SubscriptionStatusEnum
    created_at: datetime


# ================= TRAINER =================

class TrainerBase(BaseModel):
    full_name: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=20)
    email: Optional[EmailStr] = None
    specialty: Optional[str] = None
    experience_years: int = 0
    salary: Optional[float] = None


class TrainerCreate(TrainerBase):
    pass


class TrainerUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    specialty: Optional[str] = None
    experience_years: Optional[int] = None
    salary: Optional[float] = None
    status: Optional[StatusEnum] = None


class TrainerOut(TrainerBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    status: StatusEnum


# ================= STAFF =================

class StaffBase(BaseModel):
    full_name: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=20)
    email: Optional[EmailStr] = None
    role: StaffRoleEnum = StaffRoleEnum.receptionist
    salary: Optional[float] = None


class StaffCreate(StaffBase):
    username: str = Field(..., max_length=50)
    password: str = Field(..., min_length=6)


class StaffUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[StaffRoleEnum] = None
    salary: Optional[float] = None
    status: Optional[StatusEnum] = None
    password: Optional[str] = Field(None, min_length=6)


class StaffOut(StaffBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    username: str
    hire_date: date
    status: StatusEnum


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    staff: StaffOut


# ================= PT SCHEDULE (lịch tập cá nhân) =================

class PTScheduleBase(BaseModel):
    member_id: int
    trainer_id: int
    date: date
    start_time: time
    end_time: time
    notes: Optional[str] = None


class PTScheduleCreate(PTScheduleBase):
    pass


class PTScheduleUpdate(BaseModel):
    date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    status: Optional[PTScheduleStatusEnum] = None
    notes: Optional[str] = None


class PTScheduleOut(PTScheduleBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    status: PTScheduleStatusEnum


# ================= GROUP CLASS =================

class GroupClassBase(BaseModel):
    name: str = Field(..., max_length=100)
    trainer_id: Optional[int] = None
    description: Optional[str] = None
    max_participants: int = 20
    room: Optional[str] = None


class GroupClassCreate(GroupClassBase):
    pass


class GroupClassUpdate(BaseModel):
    name: Optional[str] = None
    trainer_id: Optional[int] = None
    description: Optional[str] = None
    max_participants: Optional[int] = None
    room: Optional[str] = None


class GroupClassOut(GroupClassBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class ClassScheduleBase(BaseModel):
    class_id: int
    date: date
    start_time: time
    end_time: time


class ClassScheduleCreate(ClassScheduleBase):
    pass


class ClassScheduleUpdate(BaseModel):
    date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None


class ClassScheduleOut(ClassScheduleBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    registered_count: Optional[int] = None


class ClassRegistrationCreate(BaseModel):
    class_schedule_id: int
    member_id: int


class ClassRegistrationUpdate(BaseModel):
    status: RegistrationStatusEnum


class ClassRegistrationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    class_schedule_id: int
    member_id: int
    status: RegistrationStatusEnum
    registered_at: datetime


# ================= REPORTS =================

class RevenuePoint(BaseModel):
    period: str  # ví dụ "2026-06" hoặc "2026-06-01"
    revenue: float
    subscription_count: int


class PackageSalesPoint(BaseModel):
    package_id: int
    package_name: str
    sold_count: int
    total_revenue: float


class TrainerSessionPoint(BaseModel):
    trainer_id: int
    trainer_name: str
    pt_session_count: int
    group_class_count: int


class ClassAttendancePoint(BaseModel):
    class_id: int
    class_name: str
    total_sessions: int
    total_registrations: int
    total_attended: int
    attendance_rate: float  # %


class DashboardSummary(BaseModel):
    total_members: int
    active_members: int
    total_trainers: int
    total_staff: int
    active_subscriptions: int
    revenue_this_month: float
    new_members_this_month: int
    upcoming_pt_sessions: int
    upcoming_class_sessions: int

"""
Định nghĩa toàn bộ bảng dữ liệu (ORM models) cho hệ thống quản lý phòng gym.

Các module:
- Member: Thành viên
- Package, MembershipSubscription: Gói tập & đăng ký gói
- Trainer: Huấn luyện viên
- Staff: Nhân viên (có đăng nhập hệ thống)
- PTSchedule: Lịch tập cá nhân với HLV (Personal Training)
- GroupClass, ClassSchedule, ClassRegistration: Lớp học nhóm & đăng ký lớp
"""
import enum
from datetime import datetime, date

from sqlalchemy import (
    Column, Integer, String, Float, Date, DateTime, Time,
    ForeignKey, Text, Enum as SAEnum, UniqueConstraint
)
from sqlalchemy.orm import relationship

from .database import Base


# ---------- Enums ----------

class GenderEnum(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"


class StatusEnum(str, enum.Enum):
    active = "active"
    inactive = "inactive"


class SubscriptionStatusEnum(str, enum.Enum):
    active = "active"
    expired = "expired"
    cancelled = "cancelled"


class PTScheduleStatusEnum(str, enum.Enum):
    scheduled = "scheduled"
    completed = "completed"
    cancelled = "cancelled"


class RegistrationStatusEnum(str, enum.Enum):
    registered = "registered"
    attended = "attended"
    absent = "absent"
    cancelled = "cancelled"


class StaffRoleEnum(str, enum.Enum):
    admin = "admin"
    manager = "manager"
    receptionist = "receptionist"


# ---------- 1. Quản lý thành viên ----------

class Member(Base):
    __tablename__ = "members"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=True)
    gender = Column(SAEnum(GenderEnum), default=GenderEnum.other)
    dob = Column(Date, nullable=True)
    address = Column(String(255), nullable=True)
    join_date = Column(Date, default=date.today)
    status = Column(SAEnum(StatusEnum), default=StatusEnum.active)
    note = Column(Text, nullable=True)

    subscriptions = relationship(
        "MembershipSubscription", back_populates="member", cascade="all, delete-orphan"
    )
    pt_schedules = relationship(
        "PTSchedule", back_populates="member", cascade="all, delete-orphan"
    )
    class_registrations = relationship(
        "ClassRegistration", back_populates="member", cascade="all, delete-orphan"
    )


# ---------- 2. Quản lý gói tập ----------

class Package(Base):
    __tablename__ = "packages"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    duration_days = Column(Integer, nullable=False)  # thời hạn gói (ngày)
    price = Column(Float, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(SAEnum(StatusEnum), default=StatusEnum.active)

    subscriptions = relationship("MembershipSubscription", back_populates="package")


class MembershipSubscription(Base):
    """Việc một thành viên đăng ký (mua) một gói tập cụ thể."""
    __tablename__ = "membership_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    package_id = Column(Integer, ForeignKey("packages.id"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    price_paid = Column(Float, nullable=False)
    status = Column(SAEnum(SubscriptionStatusEnum), default=SubscriptionStatusEnum.active)
    created_at = Column(DateTime, default=datetime.utcnow)

    member = relationship("Member", back_populates="subscriptions")
    package = relationship("Package", back_populates="subscriptions")


# ---------- 3. Quản lý huấn luyện viên ----------

class Trainer(Base):
    __tablename__ = "trainers"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    phone = Column(String(20), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=True)
    specialty = Column(String(150), nullable=True)  # chuyên môn: Gym, Yoga, Boxing...
    experience_years = Column(Integer, default=0)
    salary = Column(Float, nullable=True)
    status = Column(SAEnum(StatusEnum), default=StatusEnum.active)

    pt_schedules = relationship("PTSchedule", back_populates="trainer")
    group_classes = relationship("GroupClass", back_populates="trainer")


# ---------- 4. Quản lý nhân viên ----------

class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(100), nullable=False)
    phone = Column(String(20), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=True)
    role = Column(SAEnum(StaffRoleEnum), default=StaffRoleEnum.receptionist)
    salary = Column(Float, nullable=True)
    hire_date = Column(Date, default=date.today)
    username = Column(String(50), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    status = Column(SAEnum(StatusEnum), default=StatusEnum.active)


# ---------- 5. Quản lý lịch tập (PT cá nhân với HLV) ----------

class PTSchedule(Base):
    __tablename__ = "pt_schedules"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    trainer_id = Column(Integer, ForeignKey("trainers.id"), nullable=False)
    date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    status = Column(SAEnum(PTScheduleStatusEnum), default=PTScheduleStatusEnum.scheduled)
    notes = Column(Text, nullable=True)

    member = relationship("Member", back_populates="pt_schedules")
    trainer = relationship("Trainer", back_populates="pt_schedules")


# ---------- 6. Quản lý lớp học nhóm ----------

class GroupClass(Base):
    """Định nghĩa một lớp học nhóm, ví dụ 'Yoga cơ bản'."""
    __tablename__ = "group_classes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    trainer_id = Column(Integer, ForeignKey("trainers.id"), nullable=True)
    description = Column(Text, nullable=True)
    max_participants = Column(Integer, default=20)
    room = Column(String(50), nullable=True)

    trainer = relationship("Trainer", back_populates="group_classes")
    schedules = relationship(
        "ClassSchedule", back_populates="group_class", cascade="all, delete-orphan"
    )


class ClassSchedule(Base):
    """Một buổi học cụ thể (ngày/giờ) thuộc một GroupClass."""
    __tablename__ = "class_schedules"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("group_classes.id"), nullable=False)
    date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    group_class = relationship("GroupClass", back_populates="schedules")
    registrations = relationship(
        "ClassRegistration", back_populates="class_schedule", cascade="all, delete-orphan"
    )


class ClassRegistration(Base):
    """Thành viên đăng ký tham gia một buổi học nhóm cụ thể."""
    __tablename__ = "class_registrations"
    __table_args__ = (
        UniqueConstraint("class_schedule_id", "member_id", name="uq_schedule_member"),
    )

    id = Column(Integer, primary_key=True, index=True)
    class_schedule_id = Column(Integer, ForeignKey("class_schedules.id"), nullable=False)
    member_id = Column(Integer, ForeignKey("members.id"), nullable=False)
    status = Column(SAEnum(RegistrationStatusEnum), default=RegistrationStatusEnum.registered)
    registered_at = Column(DateTime, default=datetime.utcnow)

    class_schedule = relationship("ClassSchedule", back_populates="registrations")
    member = relationship("Member", back_populates="class_registrations")

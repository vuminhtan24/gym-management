"""
Entry point của ứng dụng FastAPI - Hệ thống quản lý phòng gym.

Chạy local:
    uvicorn app.main:app --reload

Xem docs tương tác tại: http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import models
from .database import engine
from .routers import (
    auth_router,
    members,
    packages,
    trainers,
    staff,
    schedules,
    classes,
    reports,
)

# Tạo toàn bộ bảng trong DB nếu chưa tồn tại
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Gym Management API",
    description="Backend quản lý phòng gym: thành viên, gói tập, huấn luyện viên, "
    "nhân viên, lịch tập, lớp học nhóm và báo cáo thống kê.",
    version="1.0.0",
)

# CORS - cho phép frontend (web/mobile) gọi API. Khi deploy production nên
# giới hạn allow_origins về domain thật của frontend thay vì "*".
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(members.router)
app.include_router(packages.router)
app.include_router(packages.sub_router)
app.include_router(trainers.router)
app.include_router(staff.router)
app.include_router(schedules.router)
app.include_router(classes.router)
app.include_router(reports.router)


@app.get("/", tags=["Root"])
def root():
    return {
        "message": "Gym Management API đang chạy. Truy cập /docs để xem tài liệu API.",
    }


@app.get("/health", tags=["Root"])
def health_check():
    return {"status": "ok"}

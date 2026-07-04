"""
Script khởi tạo dữ liệu mẫu: tài khoản admin đầu tiên + vài gói tập/HLV mẫu.

Chạy sau khi cài dependencies:
    python seed_data.py
"""
from datetime import date

from app.database import SessionLocal, engine
from app import models, auth

models.Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    # ----- Tài khoản admin đầu tiên -----
    if not db.query(models.Staff).filter(models.Staff.username == "admin").first():
        admin = models.Staff(
            full_name="Quản trị viên",
            phone="0900000000",
            email="admin@gymmanagement.com",
            role=models.StaffRoleEnum.admin,
            salary=0,
            hire_date=date.today(),
            username="admin",
            hashed_password=auth.hash_password("admin123"),
            status=models.StatusEnum.active,
        )
        db.add(admin)
        print("Đã tạo tài khoản admin -> username: admin | password: admin123")
    else:
        print("Tài khoản admin đã tồn tại, bỏ qua.")

    # ----- Gói tập mẫu -----
    if db.query(models.Package).count() == 0:
        db.add_all([
            models.Package(name="Gói 1 tháng", duration_days=30, price=500000,
                            description="Gói tập cơ bản 1 tháng"),
            models.Package(name="Gói 3 tháng", duration_days=90, price=1350000,
                            description="Gói tập 3 tháng, tiết kiệm hơn"),
            models.Package(name="Gói 6 tháng", duration_days=180, price=2400000,
                            description="Gói tập 6 tháng"),
            models.Package(name="Gói 12 tháng", duration_days=365, price=4200000,
                            description="Gói tập 1 năm, ưu đãi tốt nhất"),
        ])
        print("Đã tạo 4 gói tập mẫu.")

    # ----- Huấn luyện viên mẫu -----
    if db.query(models.Trainer).count() == 0:
        db.add_all([
            models.Trainer(full_name="Nguyễn Văn A", phone="0911111111",
                            specialty="Gym / Tăng cơ giảm mỡ", experience_years=5, salary=12000000),
            models.Trainer(full_name="Trần Thị B", phone="0922222222",
                            specialty="Yoga / Pilates", experience_years=4, salary=10000000),
        ])
        print("Đã tạo 2 huấn luyện viên mẫu.")

    db.commit()
    print("Hoàn tất seed dữ liệu.")
finally:
    db.close()

# Gym Management System

Hệ thống quản lý phòng gym gồm 2 phần độc lập, giao tiếp qua HTTP REST API:

```
gym-management/
├── backend/     # FastAPI - API, database, xác thực
└── mobile/      # Flutter - app di động cho nhân viên
```

Xem chi tiết từng phần tại `backend/README.md` và `mobile/README.md`.
File này chỉ tóm tắt cách chạy nhanh cả hệ thống.

## Yêu cầu môi trường

| Thành phần | Yêu cầu |
|---|---|
| Backend | Python 3.10+ |
| Mobile | Flutter SDK 3.x+, Android Studio hoặc Xcode (để có emulator/simulator) |

## Chạy nhanh (2 bước, 2 terminal riêng)

### Bước 1 — Backend

```bash
cd backend
python3 -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env           # tuỳ chọn, đổi SECRET_KEY nếu deploy thật
python seed_data.py            # tạo tài khoản admin/admin123 + dữ liệu mẫu
uvicorn app.main:app --reload --host 0.0.0.0
```

Kiểm tra tại `http://localhost:8000/docs` (Swagger UI).

### Bước 2 — Mobile

Thư mục `mobile/` mới chỉ có `lib/` và `pubspec.yaml` (chưa có khung
Android/iOS). Cần tạo khung project 1 lần:

```bash
flutter create temp_app
cp -r temp_app/android temp_app/ios mobile/
rm -rf temp_app
cd mobile
flutter pub get
```

Mở `mobile/lib/core/api_constants.dart`, chỉnh `baseUrl` theo môi trường
chạy (xem bảng trong `mobile/README.md`), rồi:

```bash
flutter run
```

Đăng nhập bằng `admin` / `admin123`.

## Module hiện có

| Module | Backend | Mobile |
|---|---|---|
| Đăng nhập nhân viên | ✅ | ✅ |
| Quản lý thành viên | ✅ | ✅ |
| Quản lý gói tập & đăng ký gói | ✅ | ✅ |
| Huấn luyện viên | ✅ | ⏳ chưa làm |
| Quản lý nhân viên | ✅ | ⏳ chưa làm |
| Lịch tập cá nhân (PT) | ✅ | ⏳ chưa làm |
| Lớp học nhóm | ✅ | ⏳ chưa làm |
| Báo cáo thống kê | ✅ | ⏳ chưa làm |

## Ghi chú

- Backend mặc định dùng SQLite (file `.db` không commit lên git, xem
  `.gitignore`). Đổi sang MySQL/PostgreSQL bằng biến môi trường
  `DATABASE_URL` — chi tiết trong `backend/README.md`.
- Không commit file `.env` (chứa `SECRET_KEY`) hay `mobile/android/key.properties`
  (chứa key ký app) lên GitHub — đã được loại trừ sẵn trong `.gitignore`.

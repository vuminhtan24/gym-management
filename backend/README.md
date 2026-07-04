# Gym Management API

Backend FastAPI cho hệ thống quản lý phòng gym, gồm 7 module:

1. **Quản lý thành viên** (`/members`)
2. **Quản lý gói tập** (`/packages`, `/subscriptions`)
3. **Quản lý huấn luyện viên** (`/trainers`)
4. **Quản lý nhân viên** (`/staff`, có đăng nhập qua `/auth/login`)
5. **Quản lý lịch tập cá nhân với HLV** (`/pt-schedules`)
6. **Quản lý lớp học nhóm** (`/classes`, `/classes/schedules`, `/classes/registrations`)
7. **Báo cáo thống kê** (`/reports/*`)

## Công nghệ

- FastAPI + Uvicorn
- SQLAlchemy 2.0 (ORM) — mặc định SQLite, dễ đổi sang MySQL/PostgreSQL
- Pydantic v2 (validate dữ liệu)
- JWT (python-jose) + bcrypt (passlib) cho xác thực nhân viên

## Cài đặt & chạy

```bash
cd gym_management
python3 -m venv venv
source venv/bin/activate       # Windows: venv\Scripts\activate
pip install -r requirements.txt

# (Tuỳ chọn) copy .env.example thành .env và sửa SECRET_KEY
cp .env.example .env

# Tạo tài khoản admin đầu tiên + dữ liệu mẫu (gói tập, HLV)
python seed_data.py

# Chạy server
uvicorn app.main:app --reload
```

Mở http://127.0.0.1:8000/docs để xem và thử toàn bộ API (Swagger UI).

Tài khoản admin mặc định sau khi seed:
- **username:** `admin`
- **password:** `admin123`

⚠️ Đổi mật khẩu này ngay khi dùng thật.

## Xác thực

Hầu hết endpoint yêu cầu đăng nhập. Lấy token qua:

```bash
curl -X POST http://127.0.0.1:8000/auth/login \
  -d "username=admin&password=admin123" \
  -H "Content-Type: application/x-www-form-urlencoded"
```

Dùng token trả về trong header `Authorization: Bearer <token>` cho các request tiếp theo.
Trên Swagger UI (`/docs`), bấm nút **Authorize** và nhập username/password để test luôn trên UI.

### Phân quyền nhân viên (role)

- `admin`: toàn quyền, kể cả quản lý nhân viên, xóa dữ liệu quan trọng.
- `manager`: thêm/sửa hầu hết dữ liệu (thành viên, gói tập, HLV, lớp học...), không quản lý nhân viên.
- `receptionist`: các tác vụ hàng ngày (tạo thành viên, đăng ký gói, đặt lịch, xem báo cáo) nhưng không sửa/xóa gói tập, HLV, hoặc quản lý nhân viên.

## Cấu trúc project

```
gym_management/
├── app/
│   ├── main.py           # Điểm khởi động, gộp router, tạo bảng DB
│   ├── database.py       # Kết nối SQLAlchemy
│   ├── models.py         # ORM models (7 module)
│   ├── schemas.py        # Pydantic schemas
│   ├── auth.py           # JWT, hash password, phân quyền
│   └── routers/
│       ├── auth_router.py   # Đăng nhập
│       ├── members.py       # Quản lý thành viên
│       ├── packages.py      # Gói tập + đăng ký gói
│       ├── trainers.py      # Huấn luyện viên
│       ├── staff.py         # Nhân viên
│       ├── schedules.py     # Lịch tập cá nhân (PT)
│       ├── classes.py       # Lớp học nhóm
│       └── reports.py       # Báo cáo thống kê
├── seed_data.py           # Script tạo admin + dữ liệu mẫu
├── requirements.txt
├── .env.example
└── README.md
```

## Một số API chính

| Chức năng | Method | Endpoint |
|---|---|---|
| Đăng nhập | POST | `/auth/login` |
| Danh sách/tạo thành viên | GET/POST | `/members` |
| Đăng ký gói tập | POST | `/subscriptions` |
| Danh sách HLV | GET | `/trainers` |
| Tạo lịch tập PT | POST | `/pt-schedules` |
| Tạo lớp học nhóm | POST | `/classes` |
| Tạo buổi học cụ thể | POST | `/classes/schedules` |
| Đăng ký học lớp nhóm | POST | `/classes/registrations` |
| Dashboard tổng quan | GET | `/reports/dashboard` |
| Báo cáo doanh thu theo tháng | GET | `/reports/revenue?group_by=month` |
| Báo cáo bán gói tập | GET | `/reports/package-sales` |
| Báo cáo buổi tập của HLV | GET | `/reports/trainer-sessions` |
| Tỉ lệ điểm danh lớp học | GET | `/reports/class-attendance` |
| Thành viên mới theo thời gian | GET | `/reports/new-members?group_by=month` |

## Đổi sang MySQL/PostgreSQL

Set biến môi trường `DATABASE_URL` trước khi chạy, ví dụ:

```bash
export DATABASE_URL="mysql+pymysql://user:password@localhost:3306/gym_db"
pip install pymysql   # driver cho MySQL
```

hoặc PostgreSQL:

```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/gym_db"
pip install psycopg2-binary
```

## Ghi chú mở rộng

- Muốn thêm tính năng thanh toán online (VNPay/MoMo/PayOS): thêm bảng `Payment` liên kết với `MembershipSubscription`, tạo router riêng.
- Muốn thêm thông báo nhắc lịch tập/hết hạn gói: có thể tích hợp thêm cron job hoặc Celery + gửi email/SMS.
- Đã có sẵn kiểm tra trùng giờ HLV khi tạo lịch tập PT (`pt-schedules`), và kiểm tra sức chứa tối đa khi đăng ký lớp học nhóm.

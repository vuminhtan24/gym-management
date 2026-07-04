"""
Cấu hình kết nối database dùng SQLAlchemy.
Mặc định dùng SQLite (gym.db) để chạy ngay không cần cài server DB.
Muốn đổi sang MySQL/PostgreSQL: set biến môi trường DATABASE_URL, ví dụ:
    postgresql://user:password@localhost:5432/gym_db
    mysql+pymysql://user:password@localhost:3306/gym_db
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./gym.db")

connect_args = {}
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependency cấp session DB cho từng request, tự đóng khi xong."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

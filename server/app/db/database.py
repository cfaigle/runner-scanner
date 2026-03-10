import sqlite3
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from app.core.config import get_settings

settings = get_settings()

# Use sync engine for Python 3.14 compatibility
engine = create_engine(
    settings.DATABASE_URL.replace("sqlite+aiosqlite://", "sqlite:///"),
    echo=settings.DEBUG,
    connect_args={"check_same_thread": False}
)

# Create session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Initialize database tables"""
    from app.db.models import Base
    Base.metadata.create_all(bind=engine)


def get_sync_session():
    """Get a synchronous database session"""
    return SessionLocal()

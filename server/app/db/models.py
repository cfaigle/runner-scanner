import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey, Integer, Float, Text
from sqlalchemy.orm import relationship
from app.db.database import Base


class User(Base):
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    race_entries = relationship("RaceEntry", back_populates="user")
    scans = relationship("Scan", back_populates="user")


class Race(Base):
    __tablename__ = "races"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    description = Column(Text)
    race_date = Column(DateTime, nullable=False)
    race_time = Column(String)  # e.g., "5K", "10K", "Marathon"
    start_time = Column(DateTime)  # Actual start time when race begins
    status = Column(String, default="draft")  # draft, active, completed
    selected_at = Column(DateTime)  # When this race was last selected
    is_synced = Column(Boolean, default=False)
    created_by = Column(String, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    entries = relationship("RaceEntry", back_populates="race", cascade="all, delete-orphan")
    scans = relationship("Scan", back_populates="race", cascade="all, delete-orphan")
    creator = relationship("User")


class RaceEntry(Base):
    __tablename__ = "race_entries"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    race_id = Column(String, ForeignKey("races.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    runner_name = Column(String, nullable=False)
    sex = Column(String)  # M, F, Other
    date_of_birth = Column(DateTime)
    bib_number = Column(Integer)
    runner_guid_short = Column(String(6))  # Last 6 digits of GUID for QR display
    registered_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    race = relationship("Race", back_populates="entries")
    user = relationship("User", back_populates="race_entries")
    scans = relationship("Scan", back_populates="entry", cascade="all, delete-orphan")


class Scan(Base):
    __tablename__ = "scans"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    race_id = Column(String, ForeignKey("races.id"), nullable=False)
    entry_id = Column(String, ForeignKey("race_entries.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"))  # Who scanned
    runner_guid = Column(String, nullable=False)
    scanned_at = Column(DateTime, default=datetime.utcnow, index=True)
    lap_number = Column(Integer, default=1)
    race_time_seconds = Column(Float)  # Time since race start in seconds
    lap_time_seconds = Column(Float)  # Time since last lap
    device_id = Column(String)  # Device that scanned
    is_synced = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    race = relationship("Race", back_populates="scans")
    entry = relationship("RaceEntry", back_populates="scans")
    user = relationship("User", back_populates="scans")


class Device(Base):
    __tablename__ = "devices"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    device_id = Column(String, unique=True, index=True)
    shared_secret = Column(String, nullable=False)  # For encrypted communication
    race_id = Column(String, ForeignKey("races.id"))
    is_active = Column(Boolean, default=True)
    last_sync = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    race = relationship("Race")

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


# User schemas
class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponse(UserBase):
    id: str
    is_active: bool
    is_admin: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# Race schemas
class RaceBase(BaseModel):
    name: str
    description: Optional[str] = None
    race_date: datetime
    race_time: Optional[str] = None


class RaceCreate(RaceBase):
    pass


class RaceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    race_date: Optional[datetime] = None
    race_time: Optional[str] = None
    start_time: Optional[datetime] = None
    status: Optional[str] = None


class RaceResponse(RaceBase):
    id: str
    start_time: Optional[datetime] = None
    status: str  # draft, active, completed
    selected_at: Optional[datetime] = None
    is_synced: bool
    created_by: str
    created_at: datetime
    updated_at: datetime
    entry_count: int = 0
    scan_count: int = 0
    
    class Config:
        from_attributes = True


class RaceJoinRequest(BaseModel):
    race_id: str
    shared_secret: str
    device_name: str


class RaceJoinResponse(BaseModel):
    race_id: str
    race_name: str
    shared_secret: str
    sync_interval: int
    server_url: str


# Race Entry schemas
class RaceEntryBase(BaseModel):
    runner_name: str
    sex: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    bib_number: Optional[int] = None


class RaceEntryCreate(RaceEntryBase):
    race_id: str
    user_id: str


class RaceEntryUpdate(BaseModel):
    runner_name: Optional[str] = None
    sex: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    bib_number: Optional[int] = None


class RaceEntryResponse(RaceEntryBase):
    id: str
    race_id: str
    user_id: str
    runner_guid_short: str
    registered_at: datetime
    
    class Config:
        from_attributes = True


# Scan schemas
class ScanBase(BaseModel):
    runner_guid: str
    lap_number: Optional[int] = 1
    device_id: Optional[str] = None


class ScanCreate(ScanBase):
    race_id: str
    entry_id: str


class ScanResponse(ScanBase):
    id: str
    race_id: str
    entry_id: str
    user_id: Optional[str]
    scanned_at: datetime
    race_time_seconds: Optional[float]
    lap_time_seconds: Optional[float]
    is_synced: bool
    
    class Config:
        from_attributes = True


class ScanAnnouncement(BaseModel):
    runner_name: str
    runner_id: str
    lap_number: int
    race_time: str
    lap_time: str


# Sync schemas
class SyncRequest(BaseModel):
    device_id: str
    last_sync: Optional[datetime] = None
    scans: Optional[List[ScanCreate]] = None


class SyncResponse(BaseModel):
    success: bool
    races: List[RaceResponse]
    entries: List[RaceEntryResponse]
    scans: List[ScanResponse]
    server_time: datetime


# QR Code schemas
class QRCodeData(BaseModel):
    race_id: str
    runner_guid: str
    runner_name: str
    race_name: str
    race_date: str
    short_id: str = Field(..., max_length=6)


class ServerJoinQR(BaseModel):
    server_url: str
    race_id: str
    shared_secret: str
    device_id: str

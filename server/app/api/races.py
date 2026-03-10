import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from typing import List

from app.db.database import get_db
from app.db.models import Race, RaceEntry, Scan, Device
from app.schemas.schemas import (
    RaceCreate, RaceUpdate, RaceResponse, RaceJoinRequest, RaceJoinResponse,
    RaceEntryCreate, RaceEntryUpdate, RaceEntryResponse,
    ScanCreate, ScanResponse, ScanAnnouncement,
    QRCodeData, ServerJoinQR
)
from app.core.dependencies import get_current_user, get_current_admin_user
from app.core.security import PacketEncryption
from app.db.models import User

router = APIRouter(prefix="/api/races", tags=["Races"])


@router.get("", response_model=List[RaceResponse])
async def get_races(
    skip: int = 0,
    limit: int = 100,
    status: str = None,  # Filter by status: draft, active, completed
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Race)
    if status:
        query = query.where(Race.status == status)
    
    result = db.execute(query.order_by(Race.created_at.desc()).offset(skip).limit(limit))
    races = result.scalars().all()
    
    # Get counts
    response_races = []
    for race in races:
        entry_count = db.execute(
            select(func.count()).select_from(RaceEntry).where(RaceEntry.race_id == race.id)
        ).scalar()
        scan_count = db.execute(
            select(func.count()).select_from(Scan).where(Scan.race_id == race.id)
        ).scalar()
        
        race_dict = RaceResponse.model_validate(race).model_dump()
        race_dict["entry_count"] = entry_count or 0
        race_dict["scan_count"] = scan_count or 0
        response_races.append(race_dict)
    
    return response_races


@router.post("", response_model=RaceResponse, status_code=status.HTTP_201_CREATED)
async def create_race(
    race_data: RaceCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_race = Race(
        name=race_data.name,
        description=race_data.description,
        race_date=race_data.race_date,
        race_time=race_data.race_time,
        created_by=current_user.id,
    )
    
    db.add(new_race)
    db.commit()
    db.refresh(new_race)
    
    return RaceResponse.model_validate(new_race)


@router.get("/{race_id}", response_model=RaceResponse)
async def get_race(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    return RaceResponse.model_validate(race)


@router.put("/{race_id}", response_model=RaceResponse)
async def update_race(
    race_id: str,
    race_data: RaceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    update_data = race_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(race, field, value)
    
    db.commit()
    db.refresh(race)
    
    return RaceResponse.model_validate(race)


@router.post("/{race_id}/start")
async def start_race(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Check if another race is already active
    active_race = db.execute(
        select(Race).where(Race.status == "active")
    ).scalar_one_or_none()
    
    if active_race and active_race.id != race_id:
        raise HTTPException(
            status_code=400, 
            detail=f"Another race '{active_race.name}' is already active. Stop it first."
        )
    
    # Use the first start time from any device as the official start
    if race.start_time is None:
        race.start_time = datetime.utcnow()
    
    race.status = "active"
    race.selected_at = datetime.utcnow()
    db.commit()
    db.refresh(race)
    
    return {"message": "Race started", "start_time": race.start_time.isoformat(), "status": race.status}


@router.post("/{race_id}/stop")
async def stop_race(
    race_id: str,
    confirm: bool = False,  # Require confirmation
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    if not confirm:
        # Return race info for confirmation dialog
        scan_count = db.execute(
            select(func.count()).select_from(Scan).where(Scan.race_id == race_id)
        ).scalar()
        raise HTTPException(
            status_code=400,
            detail={
                "requires_confirmation": True,
                "race_name": race.name,
                "scan_count": scan_count or 0,
                "message": f"Are you sure you want to stop '{race.name}'? {scan_count or 0} scans have been recorded."
            }
        )
    
    race.status = "completed"
    db.commit()
    
    return {"message": "Race stopped", "status": race.status}


@router.post("/{race_id}/select")
async def select_race(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Select a race to work on. Only one race can be active at a time."""
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # If race is already active, just update selected_at
    if race.status == "active":
        race.selected_at = datetime.utcnow()
        db.commit()
        db.refresh(race)
        return RaceResponse.model_validate(race)
    
    # Can only select draft or completed races
    if race.status not in ["draft", "completed"]:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot select race with status '{race.status}'"
        )
    
    race.selected_at = datetime.utcnow()
    db.commit()
    db.refresh(race)
    
    return RaceResponse.model_validate(race)


@router.get("/active")
async def get_active_race(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get the currently active race (if any)"""
    result = db.execute(
        select(Race).where(Race.status == "active")
    ).scalar_one_or_none()
    
    if not result:
        return {"active_race": None}
    
    return {"active_race": RaceResponse.model_validate(result)}


@router.post("/{race_id}/join", response_model=RaceJoinResponse)
async def join_race(
    race_id: str,
    join_data: RaceJoinRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Create device with shared secret
    device = Device(
        name=join_data.device_name,
        device_id=str(uuid.uuid4()),
        shared_secret=join_data.shared_secret,
        race_id=race_id,
    )
    
    db.add(device)
    db.commit()
    
    from app.core.config import get_settings
    settings = get_settings()
    
    return RaceJoinResponse(
        race_id=race_id,
        race_name=race.name,
        shared_secret=join_data.shared_secret,
        sync_interval=settings.SYNC_INTERVAL_SECONDS,
        server_url=f"http://<server-ip>:8000"
    )


@router.get("/{race_id}/qr-join")
async def get_race_join_qr(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Generate shared secret for this race
    shared_secret = PacketEncryption.generate_key()
    
    # Store device
    device = Device(
        name="Web Client",
        device_id=str(uuid.uuid4()),
        shared_secret=shared_secret,
        race_id=race_id,
    )
    db.add(device)
    db.commit()
    
    return ServerJoinQR(
        server_url="http://<server-ip>:8000",
        race_id=race_id,
        shared_secret=shared_secret,
        device_id=device.device_id
    )


@router.get("/{race_id}/results")
async def get_race_results(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Race).where(Race.id == race_id))
    race = result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Get all entries with their best times
    entries_result = db.execute(
        select(RaceEntry).where(RaceEntry.race_id == race_id)
    )
    entries = entries_result.scalars().all()
    
    results = []
    for entry in entries:
        scans_result = db.execute(
            select(Scan)
            .where(Scan.entry_id == entry.id)
            .order_by(Scan.race_time_seconds)
        )
        scans = scans_result.scalars().all()
        
        total_time = scans[-1].race_time_seconds if scans else None
        lap_count = len(scans)
        best_lap_time = min((s.lap_time_seconds for s in scans if s.lap_time_seconds), default=None)
        
        results.append({
            "entry": RaceEntryResponse.model_validate(entry),
            "total_time": total_time,
            "lap_count": lap_count,
            "best_lap_time": best_lap_time,
            "scans": [ScanResponse.model_validate(s) for s in scans]
        })
    
    # Sort by total time
    results.sort(key=lambda x: x["total_time"] if x["total_time"] else float('inf'))
    
    return {
        "race": RaceResponse.model_validate(race),
        "results": results
    }

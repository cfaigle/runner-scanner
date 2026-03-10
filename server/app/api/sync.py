from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from typing import List, Optional
import uuid

from app.db.database import get_db
from app.db.models import Race, RaceEntry, Scan, Device
from app.schemas.schemas import ScanCreate, ScanResponse, RaceResponse, RaceEntryResponse
from app.core.dependencies import get_current_user
from app.db.models import User

router = APIRouter(prefix="/api/sync", tags=["Sync"])


@router.get("/checkpoint/{race_id}")
async def get_checkpoint(
    race_id: str,
    device_id: str,
    last_checkpoint: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get sync state for a device.
    Returns checkpoint ID and any new scan hashes since last_checkpoint.
    """
    race = db.query(Race).filter(Race.id == race_id).first()
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Get all scans for this race, ordered by timestamp
    query = select(Scan).where(Scan.race_id == race_id).order_by(Scan.scanned_at)
    all_scans = db.execute(query).scalars().all()
    
    # Get scans since last checkpoint (simple approach: by timestamp)
    new_scans = []
    if last_checkpoint:
        # Parse checkpoint timestamp
        try:
            checkpoint_time = datetime.fromisoformat(last_checkpoint.replace('Z', '+00:00'))
            new_scans = [s for s in all_scans if s.scanned_at > checkpoint_time]
        except:
            new_scans = all_scans
    else:
        new_scans = all_scans
    
    # Generate current checkpoint (timestamp-based)
    current_checkpoint = datetime.utcnow().isoformat() + 'Z'
    
    return {
        "checkpoint": current_checkpoint,
        "race_status": race.status,
        "official_start": race.start_time.isoformat() + 'Z' if race.start_time else None,
        "new_scans": [
            {
                "hash": scan.id,  # Use scan ID as hash
                "runner_guid": scan.runner_guid,
                "timestamp": scan.scanned_at.isoformat() + 'Z',
                "device_id": scan.device_id,
                "lap_number": scan.lap_number,
                "race_time_seconds": scan.race_time_seconds,
            }
            for scan in new_scans
        ],
        "scan_count": len(all_scans),
    }


@router.post("/scans/bulk")
async def upload_scans(
    race_id: str,
    scans: List[ScanCreate],
    device_id: str,
    checkpoint: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Upload multiple scans from a device.
    Scans are merged by timestamp - no adjustments, just insert.
    """
    race = db.query(Race).filter(Race.id == race_id).first()
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    if race.status != "active":
        raise HTTPException(status_code=400, detail=f"Race is not active (status: {race.status})")
    
    created_scans = []
    for scan_data in scans:
        # Calculate race time if start time exists
        race_time = None
        lap_time = None
        
        if race.start_time:
            scan_time = datetime.utcnow()  # Use server time for consistency
            race_time = (scan_time - race.start_time).total_seconds()
        
        # Get previous scan for this runner to calculate lap
        prev_scan = db.query(Scan).filter(
            Scan.entry_id == scan_data.entry_id
        ).order_by(Scan.scanned_at.desc()).first()
        
        lap_number = 1
        if prev_scan and prev_scan.lap_number:
            lap_number = prev_scan.lap_number + 1
        
        if prev_scan and prev_scan.race_time_seconds and race_time:
            lap_time = race_time - prev_scan.race_time_seconds
        
        # Create scan
        scan = Scan(
            id=str(uuid.uuid4()),
            race_id=race_id,
            entry_id=scan_data.entry_id,
            user_id=current_user.id,
            runner_guid=scan_data.runner_guid,
            lap_number=lap_number,
            device_id=device_id,
            race_time_seconds=race_time,
            lap_time_seconds=lap_time,
            is_synced=True,
        )
        
        db.add(scan)
        created_scans.append(scan)
    
    db.commit()
    
    return {
        "success": True,
        "uploaded_count": len(created_scans),
        "checkpoint": checkpoint,
    }


@router.get("/race/{race_id}/export")
async def export_race(
    race_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Export complete race data for offline caching.
    Returns race + all participants + all scans.
    """
    race = db.query(Race).filter(Race.id == race_id).first()
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Get all entries
    entries = db.query(RaceEntry).filter(RaceEntry.race_id == race_id).all()
    
    # Get all scans
    scans = db.query(Scan).filter(Scan.race_id == race_id).all()
    
    return {
        "race": RaceResponse.model_validate(race).model_dump(),
        "entries": [RaceEntryResponse.model_validate(e).model_dump() for e in entries],
        "scans": [ScanResponse.model_validate(s).model_dump() for s in scans],
        "exported_at": datetime.utcnow().isoformat() + 'Z',
    }

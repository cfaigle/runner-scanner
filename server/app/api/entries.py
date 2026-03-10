import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List

from app.db.database import get_db
from app.db.models import Race, RaceEntry, User
from app.schemas.schemas import RaceEntryCreate, RaceEntryUpdate, RaceEntryResponse
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/api/entries", tags=["Race Entries"])


@router.get("", response_model=List[RaceEntryResponse])
async def get_entries(
    race_id: str = None,
    user_id: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(RaceEntry)
    
    if race_id:
        query = query.where(RaceEntry.race_id == race_id)
    if user_id:
        query = query.where(RaceEntry.user_id == user_id)
    
    query = query.offset(skip).limit(limit)
    
    result = db.execute(query)
    entries = result.scalars().all()
    
    return [RaceEntryResponse.model_validate(e) for e in entries]


@router.post("", response_model=RaceEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_entry(
    entry_data: RaceEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify race exists
    race_result = db.execute(select(Race).where(Race.id == entry_data.race_id))
    race = race_result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Generate GUID for runner
    runner_guid = str(uuid.uuid4())
    runner_guid_short = runner_guid.replace('-', '')[-6:].upper()
    
    # Create entry
    new_entry = RaceEntry(
        race_id=entry_data.race_id,
        user_id=entry_data.user_id,
        runner_name=entry_data.runner_name,
        sex=entry_data.sex,
        date_of_birth=entry_data.date_of_birth,
        bib_number=entry_data.bib_number,
        runner_guid_short=runner_guid_short,
    )
    
    db.add(new_entry)
    db.commit()
    db.refresh(new_entry)
    
    return RaceEntryResponse.model_validate(new_entry)


@router.get("/{entry_id}", response_model=RaceEntryResponse)
async def get_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(RaceEntry).where(RaceEntry.id == entry_id))
    entry = result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    return RaceEntryResponse.model_validate(entry)


@router.put("/{entry_id}", response_model=RaceEntryResponse)
async def update_entry(
    entry_id: str,
    entry_data: RaceEntryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(RaceEntry).where(RaceEntry.id == entry_id))
    entry = result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    update_data = entry_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(entry, field, value)
    
    db.commit()
    db.refresh(entry)
    
    return RaceEntryResponse.model_validate(entry)


@router.delete("/{entry_id}")
async def delete_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(RaceEntry).where(RaceEntry.id == entry_id))
    entry = result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    db.delete(entry)
    db.commit()
    
    return {"message": "Entry deleted"}


@router.get("/race/{race_id}/qr/{entry_id}")
async def generate_entry_qr(
    race_id: str,
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Generate QR code data for a race entry"""
    
    # Get entry with race info
    entry_result = db.execute(
        select(RaceEntry).where(RaceEntry.id == entry_id)
    )
    entry = entry_result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    race_result = db.execute(select(Race).where(Race.id == race_id))
    race = race_result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    # Generate full GUID for QR code
    runner_guid = str(uuid.uuid4())
    
    return {
        "race_id": race_id,
        "race_name": race.name,
        "race_date": race.race_date.isoformat() if race.race_date else None,
        "entry_id": entry_id,
        "runner_guid": runner_guid,
        "runner_name": entry.runner_name,
        "short_id": entry.runner_guid_short,
        "qr_data": {
            "type": "runner",
            "race_id": race_id,
            "entry_id": entry_id,
            "runner_guid": runner_guid,
            "name": entry.runner_name,
            "dob": entry.date_of_birth.isoformat() if entry.date_of_birth else None,
        }
    }

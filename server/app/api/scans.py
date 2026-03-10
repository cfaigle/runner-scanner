from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import List, Dict, Any
import json

from app.db.database import get_db
from app.db.models import Scan, Race, RaceEntry, User, Device
from app.schemas.schemas import ScanCreate, ScanResponse, ScanAnnouncement, SyncRequest, SyncResponse, RaceResponse, RaceEntryResponse
from app.core.dependencies import get_current_user
from app.core.security import PacketEncryption

router = APIRouter(prefix="/api/scans", tags=["Scans"])

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, race_id: str):
        await websocket.accept()
        if race_id not in self.active_connections:
            self.active_connections[race_id] = []
        self.active_connections[race_id].append(websocket)
    
    def disconnect(self, websocket: WebSocket, race_id: str):
        if race_id in self.active_connections:
            self.active_connections[race_id].remove(websocket)
    
    async def broadcast_to_race(self, race_id: str, message: dict):
        if race_id in self.active_connections:
            for connection in self.active_connections[race_id]:
                try:
                    await connection.send_json(message)
                except:
                    pass
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        try:
            await websocket.send_json(message)
        except:
            pass

manager = ConnectionManager()


@router.post("", response_model=ScanResponse)
async def create_scan(
    scan_data: ScanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify race exists and is active
    race_result = db.execute(select(Race).where(Race.id == scan_data.race_id))
    race = race_result.scalar_one_or_none()
    
    if not race:
        raise HTTPException(status_code=404, detail="Race not found")
    
    if race.status != "active":
        raise HTTPException(status_code=400, detail=f"Race is not active (status: {race.status})")
    
    # Verify entry exists
    entry_result = db.execute(
        select(RaceEntry).where(RaceEntry.id == scan_data.entry_id)
    )
    entry = entry_result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Race entry not found")
    
    # Calculate race time and lap time
    race_time_seconds = None
    lap_time_seconds = None
    
    if race.start_time:
        race_time_seconds = (datetime.utcnow() - race.start_time).total_seconds()
    
    # Get previous scan for lap time
    prev_scan_result = db.execute(
        select(Scan)
        .where(Scan.entry_id == scan_data.entry_id)
        .order_by(Scan.scanned_at.desc())
        .limit(1)
    )
    prev_scan = prev_scan_result.scalar_one_or_none()
    
    if prev_scan and prev_scan.race_time_seconds:
        lap_time_seconds = race_time_seconds - prev_scan.race_time_seconds if race_time_seconds else None
    
    # Create scan
    new_scan = Scan(
        race_id=scan_data.race_id,
        entry_id=scan_data.entry_id,
        user_id=current_user.id,
        runner_guid=scan_data.runner_guid,
        lap_number=scan_data.lap_number or 1,
        device_id=scan_data.device_id,
        race_time_seconds=race_time_seconds,
        lap_time_seconds=lap_time_seconds,
    )
    
    db.add(new_scan)
    db.commit()
    db.refresh(new_scan)
    
    # Broadcast to WebSocket clients
    announcement = ScanAnnouncement(
        runner_name=entry.runner_name,
        runner_id=entry.runner_guid_short,
        lap_number=new_scan.lap_number,
        race_time=format_time(race_time_seconds) if race_time_seconds else "0:00",
        lap_time=format_time(lap_time_seconds) if lap_time_seconds else "0:00"
    )
    
    await manager.broadcast_to_race(race.id, {
        "type": "scan",
        "data": announcement.model_dump()
    })
    
    return ScanResponse.model_validate(new_scan)


@router.get("", response_model=List[ScanResponse])
async def get_scans(
    race_id: str = None,
    entry_id: str = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = select(Scan)
    
    if race_id:
        query = query.where(Scan.race_id == race_id)
    if entry_id:
        query = query.where(Scan.entry_id == entry_id)
    
    query = query.order_by(Scan.scanned_at.desc()).offset(skip).limit(limit)
    
    result = db.execute(query)
    scans = result.scalars().all()
    
    return [ScanResponse.model_validate(s) for s in scans]


@router.get("/announcement/{scan_id}", response_model=ScanAnnouncement)
async def get_scan_announcement(
    scan_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = db.execute(select(Scan).where(Scan.id == scan_id))
    scan = result.scalar_one_or_none()
    
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    entry_result = db.execute(
        select(RaceEntry).where(RaceEntry.id == scan.entry_id)
    )
    entry = entry_result.scalar_one_or_none()
    
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    return ScanAnnouncement(
        runner_name=entry.runner_name,
        runner_id=entry.runner_guid_short,
        lap_number=scan.lap_number,
        race_time=format_time(scan.race_time_seconds) if scan.race_time_seconds else "0:00",
        lap_time=format_time(scan.lap_time_seconds) if scan.lap_time_seconds else "0:00"
    )


@router.websocket("/ws/{race_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    race_id: str,
    db: Session = Depends(get_db)
):
    await manager.connect(websocket, race_id)
    try:
        while True:
            # Keep connection alive, receive messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get("type") == "ping":
                await manager.send_personal_message({"type": "pong"}, websocket)
            elif message.get("type") == "sync_request":
                # Handle sync request
                await handle_sync_message(message, websocket, race_id, db)
    except WebSocketDisconnect:
        manager.disconnect(websocket, race_id)


async def handle_sync_message(message: dict, websocket: WebSocket, race_id: str, db: Session):
    """Handle sync request from client"""
    scans_data = message.get("scans", [])
    
    # Process incoming scans
    for scan_data in scans_data:
        try:
            scan_create = ScanCreate(**scan_data)
            # Create scan logic here (similar to create_scan endpoint)
        except Exception as e:
            await manager.send_personal_message({
                "type": "error",
                "message": str(e)
            }, websocket)
    
    # Send back latest data
    await manager.send_personal_message({
        "type": "sync_complete",
        "timestamp": datetime.utcnow().isoformat()
    }, websocket)


def format_time(seconds: float) -> str:
    """Format seconds as MM:SS.ms"""
    mins = int(seconds // 60)
    secs = int(seconds % 60)
    ms = int((seconds % 1) * 100)
    return f"{mins}:{secs:02d}.{ms:02d}"


@router.post("/sync")
async def sync_data(
    sync_request: SyncRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Sync scans and get latest data"""
    
    # Process incoming scans
    created_scans = []
    if sync_request.scans:
        for scan_data in sync_request.scans:
            try:
                # Validate and create scan
                race_result = db.execute(
                    select(Race).where(Race.id == scan_data.race_id)
                )
                race = race_result.scalar_one_or_none()
                
                if race and race.is_active:
                    entry_result = db.execute(
                        select(RaceEntry).where(RaceEntry.id == scan_data.entry_id)
                    )
                    entry = entry_result.scalar_one_or_none()
                    
                    if entry:
                        # Calculate times
                        race_time = None
                        lap_time = None
                        
                        if race.start_time:
                            race_time = (datetime.utcnow() - race.start_time).total_seconds()
                        
                        new_scan = Scan(
                            race_id=scan_data.race_id,
                            entry_id=scan_data.entry_id,
                            user_id=current_user.id,
                            runner_guid=scan_data.runner_guid,
                            lap_number=scan_data.lap_number or 1,
                            device_id=sync_request.device_id,
                            race_time_seconds=race_time,
                            lap_time_seconds=lap_time,
                            is_synced=True
                        )
                        
                        db.add(new_scan)
                        created_scans.append(new_scan)
            except Exception:
                continue
    
    db.commit()
    
    # Get all races, entries, and scans
    races_result = db.execute(select(Race))
    races = races_result.scalars().all()
    
    entries_result = db.execute(select(RaceEntry))
    entries = entries_result.scalars().all()
    
    scans_result = db.execute(select(Scan))
    scans = scans_result.scalars().all()
    
    return SyncResponse(
        success=True,
        races=[RaceResponse.model_validate(r) for r in races],
        entries=[RaceEntryResponse.model_validate(e) for e in entries],
        scans=[ScanResponse.model_validate(s) for s in scans],
        server_time=datetime.utcnow()
    )

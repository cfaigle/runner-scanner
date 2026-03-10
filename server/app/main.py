from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager
import os

from app.core.config import get_settings
from app.db.database import init_db
from app.api.auth import router as auth_router
from app.api.races import router as races_router
from app.api.scans import router as scans_router
from app.api.entries import router as entries_router
from app.api.sync import router as sync_router

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup - init database
    init_db()
    yield
    # Shutdown


app = FastAPI(
    title=settings.APP_NAME,
    description="Race Timing System with QR Code Scanning",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth_router)
app.include_router(races_router)
app.include_router(scans_router)
app.include_router(entries_router)
app.include_router(sync_router)

# Mount static files
# Get the server root directory (parent of app/)
server_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
static_path = os.path.join(server_root, "static")
templates_path = os.path.join(server_root, "templates")

if os.path.exists(static_path):
    app.mount("/static", StaticFiles(directory=static_path), name="static")


@app.get("/")
async def root():
    index_path = os.path.join(templates_path, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "Runner Race Timer API", "docs": "/docs"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "app": settings.APP_NAME}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )

# Runner Race Timer Server

A comprehensive race timing system with real-time sync, QR code scanning, and live results.

## Features

- **Multi-client support**: Multiple mobile devices can connect and sync scans
- **Real-time updates**: WebSocket-based live results and announcements
- **Secure authentication**: JWT-based login with bcrypt password hashing
- **Encrypted packets**: Optional encryption for scan data transmission
- **Live standings**: Real-time race results with lap tracking
- **Text-to-speech**: Announces runner scans with times
- **QR code generation**: Create runner QR codes and server join codes

## Quick Start

### 1. Install Dependencies

```bash
cd server
pip install -r requirements.txt
```

### 2. Run the Server

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Access the Web Interface

Open your browser to: `http://localhost:8000`

### 4. Connect Mobile App

1. Open the Flutter app
2. Tap the cloud icon (top right)
3. Enter server URL: `http://<your-server-ip>:8000`
4. Login or register

## API Endpoints

### Authentication
- `POST /api/auth/register` - Create new user
- `POST /api/auth/login` - Login user

### Races
- `GET /api/races` - List all races
- `POST /api/races` - Create new race
- `GET /api/races/{id}` - Get race details
- `PUT /api/races/{id}` - Update race
- `POST /api/races/{id}/start` - Start race
- `POST /api/races/{id}/stop` - Stop race
- `GET /api/races/{id}/results` - Get race results

### Entries
- `GET /api/entries` - List entries
- `POST /api/entries` - Create entry
- `GET /api/entries/{id}` - Get entry
- `PUT /api/entries/{id}` - Update entry
- `DELETE /api/entries/{id}` - Delete entry

### Scans
- `POST /api/scans` - Record scan
- `GET /api/scans` - List scans
- `GET /api/scans/announcement/{id}` - Get scan announcement
- `POST /api/scans/sync` - Sync data
- `WS /api/scans/ws/{race_id}` - WebSocket for real-time updates

## Database

The server uses SQLite by default. Database file: `race_timer.db`

### Tables
- `users` - User accounts
- `races` - Race events
- `race_entries` - Runner registrations
- `scans` - Scan records
- `devices` - Connected devices

## Configuration

Create a `.env` file in the server directory:

```env
# Server
HOST=0.0.0.0
PORT=8000

# Security
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# Sync
SYNC_INTERVAL_SECONDS=5

# Debug
DEBUG=true
```

## WebSocket Messages

### Client → Server
```json
{"type": "ping"}
{"type": "sync_request", "scans": [...]}
```

### Server → Client
```json
{"type": "scan", "data": {
  "runner_name": "John Doe",
  "runner_id": "ABC123",
  "lap_number": 1,
  "race_time": "5:23.45",
  "lap_time": "5:23.45"
}}
```

## QR Code Formats

### Runner QR Code
```json
{
  "type": "runner",
  "race_id": "...",
  "entry_id": "...",
  "runner_guid": "...",
  "name": "John Doe",
  "dob": "1990-01-01"
}
```

### Server Join QR Code
```json
{
  "type": "server_join",
  "server_url": "http://192.168.1.100:8000",
  "race_id": "...",
  "shared_secret": "...",
  "device_id": "..."
}
```

## Production Deployment

### Using Docker (recommended)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Using systemd

Create `/etc/systemd/system/race-timer.service`:

```ini
[Unit]
Description=Runner Race Timer Server
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/path/to/server
ExecStart=/path/to/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable race-timer
sudo systemctl start race-timer
```

## Security Notes

1. Change the default `SECRET_KEY` in production
2. Use HTTPS for production deployments
3. Configure CORS appropriately for your domain
4. Use strong passwords for user accounts
5. Regularly backup the SQLite database

## License

MIT License

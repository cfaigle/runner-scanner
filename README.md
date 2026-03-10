# Runner Scan - Race Timing System

A comprehensive Flutter + Python race timing system with QR code scanning, real-time sync, and live results.

## 📱 Features

### Mobile App (Flutter)
- **QR Code Scanning**: Scan runner QR codes with 10-second cooldown
- **QR Code Generation**: Create runner QR codes with name and DOB
- **Session Management**: Start/stop timing sessions
- **Server Sync**: Connect to local server for real-time data
- **Text-to-Speech**: Announces runner scans with times
- **Live Standings**: View current race results
- **Export Data**: Share scan data via CSV
- **Offline Support**: Works standalone or synced

### Web Server (Python/FastAPI)
- **Multi-client Support**: Multiple devices can sync scans
- **Real-time Updates**: WebSocket-based live results
- **Secure Login**: JWT authentication with bcrypt
- **Race Management**: Create and manage races
- **Live Dashboard**: Web-based results viewer
- **Encrypted Packets**: Optional encryption for data

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  Python Server  │
│  (Android)      │◀────│  (FastAPI)      │
└─────────────────┘     └─────────────────┘
       │                        │
       │                        │
       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐
│  Hive (Local)   │     │  SQLite (DB)    │
└─────────────────┘     └─────────────────┘
```

## 📂 Project Structure

```
runner-scan/
├── lib/                    # Flutter app code
│   ├── main.dart
│   ├── models/            # Data models
│   ├── providers/         # State management
│   ├── screens/           # UI screens
│   ├── services/          # API & business logic
│   └── widgets/           # Reusable widgets
├── server/                # Python server
│   ├── app/
│   │   ├── api/          # REST endpoints
│   │   ├── core/         # Config & security
│   │   ├── db/           # Database models
│   │   └── utils/        # Utilities
│   ├── static/           # Web assets
│   ├── templates/        # HTML templates
│   └── requirements.txt
└── README.md
```

## 🚀 Quick Start

### 1. Start the Server

```bash
cd server
./start.sh
```

Or manually:
```bash
cd server
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Run the Flutter App

```bash
flutter pub get
flutter run
```

### 3. Connect App to Server

1. Open Flutter app
2. Tap cloud icon (top right)
3. Enter server URL: `http://<server-ip>:8000`
4. Register/Login

## 📖 Usage Guide

### Creating a Race (Web)

1. Open `http://localhost:8000`
2. Register/Login
3. Click "+ New Race"
4. Enter race details (name, date, distance)
5. Click "Create"

### Adding Runners (Web)

1. Go to "Entries" tab
2. Select race
3. Click "+ Add Entry"
4. Enter runner details
5. Download QR code

### Scanning Runners (Mobile)

1. Connect to server
2. Select race
3. Start session
4. Tap "Scan Runner"
5. Scan QR code
6. Hear announcement

### Viewing Results

- **Mobile**: Tap leaderboard icon during scan session
- **Web**: Click "Results" tab

## 🔌 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register user |
| POST | `/api/auth/login` | Login user |

### Races
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/races` | List races |
| POST | `/api/races` | Create race |
| POST | `/api/races/{id}/start` | Start race |
| POST | `/api/races/{id}/stop` | Stop race |
| GET | `/api/races/{id}/results` | Get results |

### Scans
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/scans` | Record scan |
| GET | `/api/scans` | List scans |
| WS | `/api/scans/ws/{race_id}` | WebSocket |

## 🔧 Configuration

### Server (.env)
```env
HOST=0.0.0.0
PORT=8000
SECRET_KEY=your-secret-key
SYNC_INTERVAL_SECONDS=5
DEBUG=true
```

### Mobile App
- Server URL: Enter in app settings
- Auto-sync: Every 5 seconds when connected

## 📱 Mobile App Features

### Home Screen
- Start/Stop session
- Server connection status
- Quick access to scanner

### Scanner Screen
- Camera QR scanning
- Flash toggle
- 10-second cooldown per runner
- Duplicate detection
- Live announcements

### Server Connect
- Manual URL entry
- QR code scan to connect
- Race selection
- Login/Register

## 🌐 Web Interface

### Dashboard Tabs
- **Races**: Create/manage races
- **Results**: Live standings
- **Entries**: Runner management
- **Settings**: Server QR codes

### Live Features
- Real-time scan updates
- Audio announcements
- Auto-refresh results
- Position tracking

## 🔒 Security

- JWT token authentication
- Bcrypt password hashing
- Optional packet encryption
- CORS configuration
- HTTPS support (production)

## 📊 Data Model

### User
- id, username, email, password
- full_name, is_admin

### Race
- id, name, description
- race_date, start_time
- is_active

### RaceEntry
- id, race_id, user_id
- runner_name, sex, dob
- runner_guid_short (6 digits)

### Scan
- id, race_id, entry_id
- runner_guid, lap_number
- race_time, lap_time

## 🛠️ Development

### Flutter
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build APK
flutter build apk --release

# Build web
flutter build web
```

### Python Server
```bash
# Install deps
pip install -r requirements.txt

# Run server
uvicorn app.main:app --reload

# Run tests
pytest
```

## 📦 Dependencies

### Flutter
- `mobile_scanner` - QR scanning
- `qr_flutter` - QR generation
- `hive` - Local storage
- `provider` - State management
- `flutter_tts` - Text-to-speech
- `web_socket_channel` - Real-time sync

### Python
- `fastapi` - Web framework
- `sqlalchemy` - Database ORM
- `python-jose` - JWT tokens
- `websockets` - Real-time comms
- `qrcode` - QR generation
- `cryptography` - Encryption

## 🐛 Troubleshooting

### Can't connect to server
- Check server is running: `http://localhost:8000/health`
- Verify same network
- Check firewall settings

### QR codes not scanning
- Ensure good lighting
- Check camera permissions
- Clean camera lens

### No audio announcements
- Check device volume
- Verify TTS engine installed
- Restart app

## 📝 License

MIT License - See LICENSE file

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

# Quick Reference Guide

## 🚀 Starting Everything

### Terminal 1: Start Server
```bash
cd server
./start.sh
```

### Terminal 2: Start Flutter App
```bash
flutter run
```

### Access Web Interface
```
http://localhost:8000
```

## 📱 Common Workflows

### Create Your First Race

**Via Web:**
1. Go to http://localhost:8000
2. Register account
3. Click "+ New Race"
4. Fill in: Name="Morning 5K", Date=today
5. Click "Create"
6. Click "Start" button

**Via Mobile:**
1. Tap cloud icon
2. Enter: http://YOUR_IP:8000
3. Login with same account
4. Select race

### Add a Runner

**Via Web:**
1. Go to "Entries" tab
2. Select race
3. Click "+ Add Entry"
4. Name: "John Doe"
5. Click "Add Entry"
6. Click "Download QR"

**Via Mobile:**
1. Tap QR code icon
2. Enter name and DOB
3. Click "Generate"
4. Share or save QR

### Record a Scan

1. Start session (mobile)
2. Tap "Scan Runner"
3. Point camera at QR
4. Hear: "Runner John Doe..."
5. Check standings

### View Results

**Mobile:**
- During scan: Tap leaderboard icon
- See: Position, Name, Laps, Times

**Web:**
- Click "Results" tab
- Select race
- Auto-updates live

## 🔧 Configuration Quick Edit

### Change Server Port
```bash
# In server/.env
PORT=8080
```

### Change Sync Interval
```bash
# In server/.env
SYNC_INTERVAL_SECONDS=10
```

### Reset Database
```bash
cd server
rm race_timer.db
# Restart server
```

## 📊 API Quick Test

```bash
# Health check
curl http://localhost:8000/health

# Register user
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123"}'

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# List races (with token)
curl http://localhost:8000/api/races \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🐛 Quick Fixes

### Server won't start
```bash
cd server
pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

### App won't connect
1. Check same WiFi network
2. Get server IP: `ipconfig getifaddr en0` (Mac) or `hostname -I` (Linux)
3. Use http://IP:8000 in app

### Database locked
```bash
cd server
rm race_timer.db
# Restart server
```

### Audio not working
```dart
// In app, TTS is initialized automatically
// Check device volume
// Restart app if needed
```

## 📱 Mobile App Shortcuts

| Action | Button |
|--------|--------|
| Connect to server | Cloud icon (top right) |
| Create runner QR | QR code icon |
| Export data | Download icon |
| View standings | Leaderboard (during scan) |
| Toggle flash | Flash icon (in scanner) |

## 🌐 Web Interface Shortcuts

| Tab | Purpose |
|-----|---------|
| Races | Create/manage races |
| Results | Live standings |
| Entries | Add runners |
| Settings | Server QR codes |

## 🎯 Race Day Checklist

- [ ] Server running on laptop
- [ ] Mobile app connected
- [ ] Race created
- [ ] Runners registered with QR codes
- [ ] Test scan working
- [ ] Audio announcements audible
- [ ] Backup power available
- [ ] WiFi network stable

## 📞 Support

Check full documentation in:
- `README.md` - Main documentation
- `server/README.md` - Server details
- Code comments for API specifics

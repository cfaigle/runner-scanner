#!/bin/bash

# Runner Race Timer Server Startup Script

set -e

echo "🏃 Runner Race Timer Server"
echo "==========================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q -r requirements.txt

# Get local IP address for mobile app connection
if command -v ipconfig &> /dev/null; then
    # macOS
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")
elif command -v hostname &> /dev/null; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
else
    LOCAL_IP="localhost"
fi

echo ""
echo "Server starting..."
echo ""
echo "📱 Connect from mobile app:"
echo "   http://$LOCAL_IP:8000"
echo ""
echo "🌐 Web interface:"
echo "   http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start server
exec uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

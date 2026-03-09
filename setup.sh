#!/bin/bash
# ─────────────────────────────────────────────
#  Spotify Now Playing Display - Setup Script
#  Works on macOS and Raspberry Pi
# ─────────────────────────────────────────────

PORT=8888
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILE="nowplaying.html"

echo ""
echo "  ♫  Spotify Now Playing Display"
echo "  ────────────────────────────────"
echo ""

# Check the HTML file exists
if [ ! -f "$DIR/$FILE" ]; then
    echo "  ✗ $FILE not found in $DIR"
    echo "    Save the HTML artifact as '$FILE' in the same folder as this script."
    exit 1
fi

echo "  ✓ Found $FILE"
echo ""

# ─────────────────────────────────────────────
#  STEP 1: Spotify App Setup Reminder
# ─────────────────────────────────────────────
echo "  Before starting, make sure you've done this:"
echo ""
echo "  1. Go to https://developer.spotify.com/dashboard"
echo "  2. Create an app (any name)"
echo "  3. In app settings, add this Redirect URI:"
echo ""
echo "     http://127.0.0.1:$PORT/$FILE"
echo ""
echo "  ⚠  Use 127.0.0.1, NOT localhost (Spotify requires it)"
echo ""
echo "  4. Save your Client ID and Client Secret"
echo ""
read -p "  Press Enter when ready..."

# ─────────────────────────────────────────────
#  STEP 2: Start local server
# ─────────────────────────────────────────────
echo ""
echo "  Starting local server on port $PORT..."
echo ""
echo "  ➜  Open this in your browser:"
echo ""
echo "     http://127.0.0.1:$PORT/$FILE"
echo ""
echo "  ⚠  Use 127.0.0.1, NOT localhost"
echo ""
echo "  Enter your Client ID & Secret on screen, then authorize."
echo "  Once connected, it runs forever (tokens auto-refresh)."
echo ""
echo "  Press Ctrl+C to stop the server."
echo ""

cd "$DIR"
python3 -m http.server $PORT --bind 127.0.0.1
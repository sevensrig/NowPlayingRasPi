#!/bin/bash
# ─────────────────────────────────────────────
#  Lightweight Kiosk Setup for Raspberry Pi
#  Uses Pi OS Lite + minimal X11 (no desktop)
#  Much lighter than full desktop + Chromium
# ─────────────────────────────────────────────

PORT=8888
HTML_DIR="/home/pi/nowplaying"
HTML_FILE="nowplaying.html"
URL="http://127.0.0.1:$PORT/$HTML_FILE"

echo ""
echo "  ♫  Spotify Now Playing - Lightweight Kiosk Setup"
echo "  ─────────────────────────────────────────────────"
echo ""

# ── Step 1: Install minimal packages ──
echo "  Installing minimal X11, window manager, and Chromium..."
echo "  (This skips the full desktop environment)"
echo ""

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  xserver-xorg-video-all \
  xserver-xorg-input-all \
  xserver-xorg-core \
  xinit \
  x11-xserver-utils \
  chromium-browser \
  openbox \
  unclutter
echo ""
echo "  ✓ Packages installed"

# ── Step 2: Web server systemd service ──
echo "  Setting up web server service..."

sudo tee /etc/systemd/system/nowplaying-server.service > /dev/null <<EOF
[Unit]
Description=Now Playing Web Server
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$HTML_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --bind 127.0.0.1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nowplaying-server.service
sudo systemctl start nowplaying-server.service
echo "  ✓ Web server service created and enabled"

# ── Step 3: Create kiosk launch script ──
echo "  Creating kiosk launch script..."

cat > "$HTML_DIR/kiosk.sh" <<'KIOSK'
#!/bin/bash
# Disable screen blanking and power management
xset -dpms
xset s off
xset s noblank

# Hide cursor after 0.5s idle
unclutter -idle 0.5 -root &

# Launch Chromium in kiosk mode (minimal flags for performance)
chromium-browser \
  --kiosk \
  --incognito \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --disable-component-update \
  --disable-background-networking \
  --disable-sync \
  --disable-default-apps \
  --disable-extensions \
  --disable-gpu \
  --no-first-run \
  --window-position=0,0 \
  KIOSK_URL
KIOSK

# Inject the actual URL
sed -i "s|KIOSK_URL|$URL|" "$HTML_DIR/kiosk.sh"
chmod +x "$HTML_DIR/kiosk.sh"
echo "  ✓ Kiosk script created"

# ── Step 4: Auto-start X + kiosk on boot ──
echo "  Configuring auto-start on boot..."

# Enable console autologin via raspi-config non-interactive
sudo raspi-config nonint do_boot_behaviour B2

# Create .bash_profile to auto-start X on login
cat >> /home/pi/.bash_profile <<'PROFILE'

# Auto-start kiosk on first console
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  startx /home/pi/nowplaying/kiosk.sh -- -nocursor
fi
PROFILE

echo "  ✓ Auto-start configured (console autologin → X → Chromium)"

# ── Step 5: Disable screen blanking in config.txt ──
if ! grep -q "consoleblank=0" /boot/config.txt 2>/dev/null; then
  echo "consoleblank=0" | sudo tee -a /boot/config.txt > /dev/null
fi
if ! grep -q "consoleblank=0" /boot/firmware/config.txt 2>/dev/null; then
  echo "consoleblank=0" | sudo tee -a /boot/firmware/config.txt > /dev/null 2>&1
fi
echo "  ✓ Screen blanking disabled"

echo ""
echo "  ─────────────────────────────────────────────────"
echo "  All done! This setup runs:"
echo ""
echo "    Pi OS Lite → console autologin → minimal X11"
echo "    → Openbox (tiny WM) → Chromium kiosk"
echo ""
echo "  No full desktop, no file manager, no taskbar."
echo "  Much lighter than the standard desktop setup."
echo ""
echo "  Memory usage: ~150-200MB vs ~500MB+ with full desktop"
echo ""
echo "  Next steps:"
echo "    1. sudo reboot"
echo "    2. Chromium opens fullscreen automatically"
echo "    3. Enter Spotify credentials once"
echo "    4. It runs hands-free after that"
echo ""
echo "  Tips:"
echo "    - Ctrl+Alt+F2 to switch to a terminal if needed"
echo "    - Ctrl+Alt+F1 to get back to the kiosk"
echo "    - Ctrl+Alt+Backspace to kill X and restart"
echo "  ─────────────────────────────────────────────────"
echo ""
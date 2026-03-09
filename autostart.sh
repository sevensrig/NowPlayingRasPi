#!/bin/bash
# ─────────────────────────────────────────────
#  Lightweight Kiosk Setup for Raspberry Pi
#  Uses Pi OS Lite + minimal X11 (no desktop)
# ─────────────────────────────────────────────

PORT=8888
USER=$(whoami)
HOME_DIR=$(eval echo ~$USER)
HTML_DIR="$HOME_DIR/nowplaying"
HTML_FILE="nowplaying.html"
URL="http://127.0.0.1:$PORT/$HTML_FILE"

echo ""
echo "  ♫  Spotify Now Playing - Lightweight Kiosk Setup"
echo "  ─────────────────────────────────────────────────"
echo "  User: $USER"
echo "  Home: $HOME_DIR"
echo ""

# ── Step 1: Install minimal packages ──
echo "  Installing minimal X11, window manager, and Chromium..."
echo ""

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  xserver-xorg-video-all \
  xserver-xorg-input-all \
  xserver-xorg-core \
  xinit \
  x11-xserver-utils \
  chromium \
  openbox \
  unclutter

# Add user to required groups
sudo usermod -a -G tty,video,input $USER

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
User=$USER
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

cat > "$HTML_DIR/kiosk.sh" <<KIOSK
#!/bin/bash
# Disable screen blanking and power management
xset -dpms
xset s off
xset s noblank

# Hide cursor after 0.5s idle
unclutter -idle 0.5 -root &

# Launch Chromium in kiosk mode
chromium \\
  --kiosk \\
  --incognito \\
  --noerrdialogs \\
  --disable-infobars \\
  --disable-session-crashed-bubble \\
  --disable-features=TranslateUI \\
  --disable-component-update \\
  --disable-background-networking \\
  --disable-sync \\
  --disable-default-apps \\
  --disable-extensions \\
  --no-first-run \\
  --start-fullscreen \\
  --window-size=1920,1080 \\
  --window-position=0,0 \\
  --force-device-scale-factor=1 \\
  $URL
KIOSK

chmod +x "$HTML_DIR/kiosk.sh"
echo "  ✓ Kiosk script created"

# ── Step 4: Allow X to start without root ──
echo "  Configuring X permissions..."

sudo tee /etc/X11/Xwrapper.config > /dev/null <<EOF
allowed_users=anybody
needs_root_rights=yes
EOF

echo "  ✓ X permissions configured"

# ── Step 5: Auto-start X + kiosk on boot ──
echo "  Configuring auto-start on boot..."

# Enable console autologin
sudo raspi-config nonint do_boot_behaviour B2

# Create .bash_profile to auto-start X on login (avoid duplicates)
KIOSK_LINE="if [ -z \"\$DISPLAY\" ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then startx $HTML_DIR/kiosk.sh -- -nocursor; fi"

if ! grep -q "startx.*kiosk.sh" "$HOME_DIR/.bash_profile" 2>/dev/null; then
  echo "" >> "$HOME_DIR/.bash_profile"
  echo "$KIOSK_LINE" >> "$HOME_DIR/.bash_profile"
fi

echo "  ✓ Auto-start configured"

# ── Step 6: Disable screen blanking ──
for cfg in /boot/config.txt /boot/firmware/config.txt; do
  if [ -f "$cfg" ] && ! grep -q "consoleblank=0" "$cfg"; then
    echo "consoleblank=0" | sudo tee -a "$cfg" > /dev/null
  fi
done
echo "  ✓ Screen blanking disabled"

echo ""
echo "  ─────────────────────────────────────────────────"
echo "  All done! This setup runs:"
echo ""
echo "    Pi OS Lite → console autologin → minimal X11"
echo "    → Chromium kiosk (fullscreen)"
echo ""
echo "  Next steps:"
echo "    1. sudo reboot"
echo "    2. Chromium opens fullscreen automatically"
echo "    3. Enter Spotify credentials once"
echo "    4. It runs hands-free after that"
echo ""
echo "  Tips:"
echo "    - Ctrl+Alt+F2 for a terminal"
echo "    - Ctrl+Alt+F1 to get back to kiosk"
echo "    - Ctrl+Alt+Backspace to restart X"
echo "  ─────────────────────────────────────────────────"
echo ""
#!/usr/bin/env bash
# Overlay 0089a9d3 — specific install steps after main bootstrap.
# Use case: refurb laptop stock monitor (iused.nl) + Telegram alerts.

set -euo pipefail

log() { printf "\033[1;36m[overlay]\033[0m %s\n" "$*"; }

log "Applying overlay 0089a9d3..."

# 1. Copy iused-monitor.py to workspace
SCRIPTS_DIR="$HOME/.openclaw/workspace/toolbox/scripts"
mkdir -p "$SCRIPTS_DIR"
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/scripts/iused-monitor.py \
  -o "$SCRIPTS_DIR/iused-monitor.py"
chmod +x "$SCRIPTS_DIR/iused-monitor.py"

# 2. Install Python deps for monitor
pip3 install --quiet --user requests beautifulsoup4

# 3. LaunchAgent for 30-min cron
PLIST="$HOME/Library/LaunchAgents/nl.user.iused-monitor.plist"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>nl.user.iused-monitor</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>python3</string>
    <string>${SCRIPTS_DIR}/iused-monitor.py</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>USED_URL</key><string>https://www.iused.nl/refurbished/macbook/</string>
    <key>USED_FILTER</key><string>M[123]</string>
    <key>USED_MAX_PRICE</key><string>1500</string>
    <key>TELEGRAM_TARGET</key><string>telegram:REPLACE_USER_ID</string>
    <key>STATE_FILE</key><string>${HOME}/.openclaw/workspace/toolbox/data/iused-state.json</string>
  </dict>
  <key>StartInterval</key><integer>1800</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/tmp/iused-monitor.log</string>
  <key>StandardErrorPath</key><string>/tmp/iused-monitor.err</string>
</dict>
</plist>
EOF

log "LaunchAgent created at $PLIST"
log "⚠️  Edit it to set TELEGRAM_TARGET = telegram:<user_id> before activating"
log ""
log "To activate after editing:"
log "  launchctl bootstrap gui/\$UID $PLIST"
log "  launchctl list | grep iused"
log ""
log "To run once manually (dry-run, no Telegram):"
log "  python3 $SCRIPTS_DIR/iused-monitor.py"
log ""
log "Overlay 0089a9d3 applied."

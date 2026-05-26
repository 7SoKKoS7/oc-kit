# Overlay 0089a9d3

Refurb laptop stock monitor — iused.nl → Telegram alerts.

Apply after main bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/x/0089a9d3/install.sh | bash
```

Then edit the LaunchAgent plist to set your Telegram user ID:

```bash
nano ~/Library/LaunchAgents/nl.user.iused-monitor.plist
# Find TELEGRAM_TARGET = telegram:REPLACE_USER_ID
# Replace REPLACE_USER_ID with your actual ID from Telegram
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/nl.user.iused-monitor.plist
```

Test once manually:

```bash
python3 ~/.openclaw/workspace/toolbox/scripts/iused-monitor.py
```

If you see `OK: N new listings`, monitoring works.

# Overlay 0089a9d3 — Mark Hagendijk (Compudata)

OpenClaw + iused.nl MacBook stock monitor → @Comp707bot Telegram alerts.

## Install (Mark-specific runbook)

This client has a **dedicated INSTALL.md** with all unneeded paths removed
(no Tailscale, no SSH, no Codex CLI, no Gemini fallback, no Gmail).

Run from Mark's Mac via Claude Code (Konstantin's Anthropic Max auth):

```
Read and execute every step in https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/x/0089a9d3/INSTALL.md on this Mac.
Ask me for inputs only at [ASK USER] / [ASK MARK] markers.
If a step fails twice, stop and report the exact error.
After successful Phase 9, await my "ja" before running Phase 10 cleanup.
```

## Files in this overlay

| File | Purpose |
|---|---|
| `INSTALL.md` | Mark-specific 10-phase runbook (~200 lines) |
| `install.sh` | Phase 7 helper — downloads iused-monitor.py + creates LaunchAgent |

## Components installed

- OpenClaw core (LaunchAgent, auto-restart)
- OpenAI provider (Mark's own API key, chmod 600 in `~/.openclaw/.env`)
- Telegram channel paired to `@Comp707bot`
- `iused-monitor.py` in `~/.openclaw/workspace/toolbox/scripts/`
- `nl.user.iused-monitor` LaunchAgent (30 min interval)

## Components explicitly NOT installed

- Tailscale (Mark didn't pay for permanent remote access)
- SSH public key (same reason)
- Codex CLI (using direct API key, simpler)
- Gemini Free / Google plugin (Mark said niet nodig)
- Gmail integration (Mark said niet nodig)

## Post-install tuning (Mark can do via @Comp707bot chat)

```
filter MacBook Pro                ← only Pro, not Air
max 1200                          ← lower price cap
filter geen filter / alles        ← widest filter
frequency 60                      ← every hour instead of 30 min
```

Bot understands NL commands and adjusts LaunchAgent EnvironmentVariables.

## Maintenance

- Logs: `tail -f /tmp/iused-monitor.log` + `tail -f ~/.openclaw/gateway.log`
- Restart: `launchctl bootout gui/$UID ~/Library/LaunchAgents/nl.user.iused-monitor.plist && launchctl bootstrap gui/$UID ~/Library/LaunchAgents/nl.user.iused-monitor.plist`
- Disable temporarily: `launchctl bootout gui/$UID ~/Library/LaunchAgents/nl.user.iused-monitor.plist`

## Support

WhatsApp: +31 6 13608863 (Konstantin / SoKKoS)

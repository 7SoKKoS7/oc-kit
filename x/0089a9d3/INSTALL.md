# Mark Hagendijk (Compudata) — OpenClaw installatie runbook

> **Slug:** 0089a9d3
> **Generated:** 2026-05-28
> **Use case:** iused.nl MacBook stock monitor → @Comp707bot Telegram alerts
> **Hardware:** MacBook Pro 2021 M1 Pro 16GB/512GB (headless via RustDesk)

You are Claude Code running on Mark's Mac. Execute every step sequentially. Mark heeft expliciet bevestigd: alleen wat hieronder staat — **geen Tailscale, geen SSH, geen Gemini, geen Codex CLI, geen Gmail integratie**.

## Mode of operation

- Run one step at a time. Verify each succeeds before moving on.
- `[ASK USER]` = stop and wait for Konstantin's reply.
- `[ASK MARK]` = wait for Mark's reply (Konstantin proxies via WhatsApp).
- If a step fails twice → STOP and print the exact error.
- NEVER write API keys/tokens to git-tracked files (only `~/.openclaw/.env` chmod 600).

---

## Phase 1 — Pre-flight checks

```bash
# 1.1 macOS version (need ≥14)
sw_vers -productVersion

# 1.2 Homebrew (install if missing)
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1.3 Core deps
brew install python@3.11 node jq git

# 1.4 Verify
python3 --version  # expect 3.11+
node --version
```

If any package fails, ask Konstantin before retrying.

---

## Phase 2 — Headless 24/7 + auto-login (Mark pre-approved)

```bash
sudo pmset -a sleep 0 disksleep 0 standby 0 womp 1 autorestart 1
sudo pmset -a lidwake 1
pmset -g | head -15      # verify

# Auto-login enable (Mark goedgekeurd vóór de sessie)
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$(whoami)"
```

Note voor Mark: na Phase 9 controleer System Settings → Users & Groups → Automatic login (Touch ID/wachtwoord kan nog vereist zijn).

---

## Phase 3 — OpenClaw install

```bash
curl -fsSL https://openclaw.io/install.sh | bash
openclaw init
openclaw status   # wacht tot gateway up (~10s)
```

If errors:
```bash
tail -50 ~/.openclaw/gateway.log
```

---

## Phase 4 — Nederlandse persona toepassen (pre-set: NL + naam=Mark)

```bash
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/nl/SOUL.md \
  > ~/.openclaw/workspace/SOUL.md
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/nl/USER.md \
  > ~/.openclaw/workspace/USER.md
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/nl/MEMORY.md \
  > ~/.openclaw/workspace/MEMORY.md

# Replace placeholder met Mark's naam
sed -i '' 's/{{CLIENT_NAME}}/Mark/g' ~/.openclaw/workspace/USER.md
```

No `[ASK USER]` — language en name al bekend.

---

## Phase 5 — AI provider: OpenAI direct (Mark's own API key)

Mark heeft een OpenAI API key (ChatGPT Pro abonnement + eigen platform.openai.com key). Geen Codex CLI, geen Gemini, geen Plus OAuth.

`[ASK MARK]`: "Mark, plak hier uw OpenAI API key (begint met `sk-`). De key wordt **alleen** opgeslagen in `~/.openclaw/.env` op uw eigen Mac, chmod 600. Niemand anders ziet 'm — ook ik niet."

Wait for Mark to paste the key directly.

```bash
# Mark plakt key — agent leest input variable als $OPENAI_KEY
echo "OPENAI_API_KEY=${OPENAI_KEY}" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env

openclaw configure provider add openai
openclaw status   # verify provider auth: ok
```

If `auth: ok` does not appear within 30s — STOP, ask Konstantin.

---

## Phase 6 — Telegram bot pairing

Mark's bot bestaat al: **@Comp707bot**

`[ASK USER]` Konstantin: "Plak Mark's bot token (uit credentials.md):"

```bash
openclaw channel telegram add --token "${BOT_TOKEN}"
```

`[ASK MARK]`: "Mark, open Telegram op uw telefoon, zoek **@Comp707bot**, druk Start. Zeg 'klaar' wanneer u dat gedaan heeft."

Wait for Mark's "klaar".

```bash
openclaw pairing list-pending
# Output toont pairing code en Mark's Telegram user_id

# Konstantin: lees code from output → approve
openclaw pairing approve telegram <code>

# Test bericht
MARK_TG_ID=$(openclaw pairing list --channel telegram --json | jq -r '.[-1].userId')
openclaw message send --channel telegram --target "telegram:${MARK_TG_ID}" \
  --message "🤖 OpenClaw draait op uw Mac. Test bericht."
```

`[ASK MARK]`: "Heeft u het testbericht ontvangen?"

If "ja" → continue. If "nee" → check `openclaw status` + `tail -50 ~/.openclaw/gateway.log`.

---

## Phase 7 — iused.nl monitor overlay

```bash
# 7.1 Apply overlay (downloads iused-monitor.py + creates LaunchAgent)
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/x/0089a9d3/install.sh | bash

# 7.2 Patch LaunchAgent met Mark's Telegram user_id (auto)
PLIST=~/Library/LaunchAgents/nl.user.iused-monitor.plist
sed -i '' "s|telegram:REPLACE_USER_ID|telegram:${MARK_TG_ID}|" "$PLIST"

# 7.3 Activate LaunchAgent
launchctl bootstrap gui/$UID "$PLIST"
launchctl list | grep iused   # verify loaded

# 7.4 Manual test run (verify scraping + notification works)
python3 ~/.openclaw/workspace/toolbox/scripts/iused-monitor.py
# Expected output: "OK: N new listings (or 0 if first run captures baseline)"
```

Default filter: M1/M2/M3 chips, max €1500, 30 min interval. Mark kan dit later aanpassen via @Comp707bot chat ("filter X, max Y, frequency Z").

---

## Phase 8 — Smoke tests

```bash
# 8.1 OpenClaw alive
openclaw status | grep -E "state|provider"
# Expected: state=ok, provider openai auth=ok

# 8.2 iused monitor loaded
launchctl list | grep iused
# Expected: nl.user.iused-monitor with PID or 0 (idle)

# 8.3 Final test message
openclaw message send --channel telegram --target "telegram:${MARK_TG_ID}" \
  --message "✅ Installatie compleet. iused.nl monitor draait elke 30 min."
```

---

## Phase 9 — Final report (Nederlands)

Print to console:

```
═══════════════════════════════════════
✅ OpenClaw installatie compleet

Mac:              $(hostname -s)
macOS:            $(sw_vers -productVersion)
Telegram bot:     @Comp707bot
AI provider:      OpenAI (uw eigen API key)
iused.nl monitor: elke 30 min, M1/M2/M3 ≤ €1500
Workspace:        ~/.openclaw/workspace/

Logs:
  tail -f ~/.openclaw/gateway.log
  tail -f /tmp/iused-monitor.log

Bij problemen:
  WhatsApp: +31 6 13608863 (Konstantin / SoKKoS)
═══════════════════════════════════════
```

Then send same summary to Mark via Telegram bot.

---

## Phase 10 — Cleanup (ALLEEN na Konstantin's bevestiging)

`[ASK USER]` Konstantin: "Alles werkt? Cleanup uitvoeren? (ja/nee)"

If Konstantin says "ja":

```bash
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/scripts/claude-code-uninstall.sh | bash
```

This removes:
- ✅ Claude Code (`~/.claude/`, `~/.local/share/claude`, caches)
- ✅ Anthropic OAuth tokens (in `~/.claude/auth.json`)
- ✅ PATH/alias entries (surgical sed — alleen Claude Code installer lijnen)

Does NOT remove:
- ❌ OpenClaw (production system — moet blijven draaien)
- ❌ Mark's `.zsh_history` / `.bash_history` (Mark's eigen geschiedenis)
- ❌ Homebrew packages (python/node/jq/git — gedeelde deps)

After cleanup, Konstantin disconnects RustDesk.

---

## Constraints (hard rules)

- NEVER install Tailscale or SSH public key (out of scope — Mark betaalde alleen €49 install, geen permanent remote access)
- NEVER install Gemini/Google plugins or Gmail integration (Mark Q4 niet nodig)
- NEVER install Codex CLI / `openai/codex/codex` brew tap (gebruiken direct API key)
- NEVER write Mark's OpenAI key to any file outside `~/.openclaw/.env`
- NEVER skip Phase 8 smoke tests
- NEVER run Phase 10 cleanup before Konstantin explicit "ja"
- If user asks you to skip a phase: ask Konstantin (WhatsApp) before agreeing

---

## Failure recovery

If any phase fails twice:

1. Print exact failing step + last 30 lines of relevant log
2. WhatsApp Konstantin (+31 6 13608863) een screenshot van de error
3. Exit without running Phase 10 cleanup (laat OpenClaw status zoals het is voor diagnostics)
4. Konstantin kan resume via: `claude` → "Resume from Phase N, last error: ..."

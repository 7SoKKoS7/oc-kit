# Mark Hagendijk (Compudata) — OpenClaw installatie runbook

> **Slug:** 0089a9d3
> **Generated:** 2026-05-28
> **Use case:** iused.nl MacBook stock monitor → @Comp707bot Telegram alerts
> **Hardware:** MacBook Pro 2021 M1 Pro 16GB/512GB (headless via RustDesk)

**Operator checklist for Konstantin** — execute manually via RustDesk session to Mark's Mac. No Claude Code or Anthropic credentials are installed on Mark's Mac. All commands typed into Mark's Terminal via RustDesk clipboard sharing.

Mark explicitly confirmed: install **alleen wat hieronder staat** — geen Tailscale, geen SSH, geen Gemini, geen Gmail integratie. Geen permanente remote-access voor Konstantin.

## Mode of operation

- Manual mode. Konstantin reads each step, types command via RustDesk Terminal on Mark's Mac.
- `[ASK MARK]` = ask Mark live (RustDesk chat / WhatsApp), use his answer.
- If a step fails twice → STOP, diagnose via WhatsApp screenshot to Konstantin (this is his own runbook, he is Konstantin).
- NEVER write API keys/tokens to git-tracked files (only `~/.openclaw/.env` chmod 600).
- Provider choice (Phase 5) is **decided live** with Mark — see options below.

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

## Phase 5 — AI provider (decided live with Mark)

Mark heeft **beide** beschikbaar — ChatGPT Pro abonnement én eigen OpenAI API key. Op moment van install kies één van drie paden:

### Pad A — alleen API key (snelst, ~€1/mnd voor iused use case)

`[ASK MARK]`: "Plak uw OpenAI API key (sk-...) — wordt alleen opgeslagen in `~/.openclaw/.env` chmod 600 op uw Mac."

```bash
echo "OPENAI_API_KEY=${OPENAI_KEY}" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw configure provider add openai
openclaw status   # verify auth: ok
```

### Pad B — alleen ChatGPT Pro (Codex CLI, valt onder $200/mnd plan, geen extra €)

```bash
brew install openai/codex/codex
codex auth   # opens browser — Mark logs in to ChatGPT Pro
openclaw configure provider add openai-codex
openclaw status   # verify auth: ok
```

### Pad C — hybrid (Pro primair + API als fallback, beste lange termijn)

```bash
# 1. Codex (Pro) als primair
brew install openai/codex/codex
codex auth
openclaw configure provider add openai-codex

# 2. API key als fallback
echo "OPENAI_API_KEY=${OPENAI_KEY}" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw configure provider add openai

# 3. Set fallback chain
openclaw configure agent main \
  --model openai-codex/gpt-5-5 \
  --fallback openai/gpt-5-5

openclaw status   # both providers auth: ok
```

**Default tijdens install:** vraag Mark wat hij prefereert. Pad C is langeretermijn beste (no surprises bij verbruik), Pad A is snelst voor demo, Pad B vermijdt elke € maar Codex CLI install kan vies zijn.

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

## Phase 10 — Verify no Anthropic footprint on Mark's Mac

Manuele install = geen Claude Code op Mark's Mac. Niets te verwijderen. Quick verify:

```bash
ls ~/.claude/ 2>&1 | head -3
ls ~/.local/share/claude 2>&1 | head -3
command -v claude && echo "⚠️  claude found unexpectedly" || echo "✅ no claude CLI"
test -f ~/.openclaw/.env && stat -f "%Sp" ~/.openclaw/.env   # expect -rw-------
ls -la ~/Library/LaunchAgents/nl.user.iused-monitor.plist    # iused-monitor LaunchAgent loaded
```

Als iets onverwacht: draai eenmalig `curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/scripts/claude-code-uninstall.sh | bash` (verwijdert Claude Code traces als ze bestaan, behoudt OpenClaw + Mark's shell history).

After verify clean, Konstantin disconnects RustDesk.

---

## Constraints (hard rules)

- NEVER install Tailscale or SSH public key (out of scope — Mark betaalde alleen €49 install, geen permanent remote access)
- NEVER install Gemini/Google plugins or Gmail integration (Mark Q4 niet nodig)
- NEVER install Claude Code op Mark's Mac (manueel installeren, geen autonomous agent)
- NEVER write Mark's OpenAI key to any file outside `~/.openclaw/.env`
- NEVER skip Phase 8 smoke tests
- NEVER run Phase 10 cleanup before Konstantin explicit "ja"
- If user asks you to skip a phase: ask Konstantin (WhatsApp) before agreeing

---

## Failure recovery

If any phase fails twice:

1. Note exact failing step + last 30 lines of relevant log
2. Diagnose via co-pilot chat (Konstantin shares output, gets next command)
3. Laat OpenClaw status zoals het is voor diagnostics
4. Resume from failed step na fix — geen agent state om te restoren (manuele mode)

# Install Instructions for Claude Code

You are Claude Code running on a fresh Mac. Execute the steps below to install
OpenClaw and configure it for the user.

## Mode of operation

- Run commands one at a time. Verify each succeeds before moving on.
- Ask the user for inputs marked **[ASK USER]**. Wait for response.
- If a step fails twice, STOP and report the exact error.
- Never store API keys or tokens in any file outside `~/.openclaw/.env`.

---

## Phase 1 — Pre-flight checks

```bash
# 1.1 macOS version (need ≥14)
sw_vers -productVersion

# 1.2 Homebrew (install if missing)
command -v brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 1.3 Core deps
brew install python@3.11 node jq tailscale git

# 1.4 Verify
python3 --version  # expect 3.11+
node --version
tailscale version
```

If any package fails to install, ask user before retrying.

---

## Phase 2 — Headless 24/7 configuration

```bash
sudo pmset -a sleep 0 disksleep 0 standby 0 womp 1 autorestart 1
sudo pmset -a lidwake 1  # optional, for laptops
pmset -g | head -15      # verify settings applied
```

Auto-login (for headless setups where no one will be at the keyboard):

[ASK USER]: "Hello, your Mac will run headless (no monitor). Enable auto-login at boot?
This means anyone with physical access boots into your account. OK?"

If YES:
```bash
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$(whoami)"
# Note: System Settings → Users & Groups → set "Automatic login" manually if needed
```

---

## Phase 3 — OpenClaw install

```bash
# 3.1 Download installer
curl -fsSL https://openclaw.io/install.sh | bash

# 3.2 Init workspace
openclaw init

# 3.3 Verify
openclaw status
```

Wait for gateway to come up (~10 seconds). If `openclaw status` shows errors,
read the latest log:
```bash
tail -50 ~/.openclaw/gateway.log
```

---

## Phase 4 — Apply persona templates

[ASK USER]: "Which language do you prefer for your assistant — Nederlands, Русский, English?"

Based on answer, copy the corresponding persona:
```bash
# Detect language from user reply, set $LANG to nl|ru|en
LANG=nl  # or ru, en

curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/$LANG/SOUL.md \
  > ~/.openclaw/workspace/SOUL.md
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/$LANG/USER.md \
  > ~/.openclaw/workspace/USER.md
curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/personas/$LANG/MEMORY.md \
  > ~/.openclaw/workspace/MEMORY.md
```

[ASK USER]: "What's your first name? (will be saved in USER.md)"

Replace `{{CLIENT_NAME}}` placeholder in USER.md with the answer.

---

## Phase 5 — Configure AI provider

[ASK USER]: "Which AI provider do you want to use? ChatGPT Plus (subscription),
OpenAI API key, Google Gemini Free, or all?"

### If ChatGPT Plus
```bash
# Codex CLI uses OAuth — user logs in via browser
brew install openai/codex/codex
codex auth  # opens browser
# user authorizes in ChatGPT, returns to terminal
```

Then configure OpenClaw to use Codex:
```bash
openclaw configure provider add openai-codex
# follow wizard
```

### If OpenAI API key
[ASK USER]: "Paste your OpenAI API key (sk-...). It will be stored in
~/.openclaw/.env — never committed to git."

```bash
echo "OPENAI_API_KEY=<paste-here>" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw configure provider add openai
```

### If Gemini Free
[ASK USER]: "Open https://aistudio.google.com/apikey and create a free API key.
Paste it here:"

```bash
echo "GEMINI_API_KEY=<paste-here>" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
openclaw configure provider add gemini-free
```

After provider added, verify:
```bash
openclaw status  # provider should show as "auth: ok"
```

---

## Phase 6 — Telegram bot pairing

[ASK USER]: "Do you have a Telegram bot token from @BotFather? If not:
1. Open Telegram on your phone, search @BotFather
2. Send /newbot, choose a name and username
3. Copy the token (looks like 1234567:ABC...) and paste here."

Wait for token, then:
```bash
openclaw channel telegram add --token "<paste-here>"

# User sends /start to their bot
# Wait, then approve pairing:
openclaw pairing list-pending
openclaw pairing approve telegram <code-shown>
```

Test:
```bash
openclaw message send --channel telegram --target "telegram:<user-id>" \
  --message "🤖 OpenClaw is alive on your Mac!"
```

---

## Phase 7 — Remote support setup (Tailscale)

```bash
sudo tailscale up --hostname="$(hostname -s)" --ssh
tailscale ip -4  # SAVE THIS IP FOR THE USER
```

Report the Tailscale IP. Tell user: "Your Mac is now accessible via SSH at
`<tailscale-ip>` from any device in the tailnet."

Add SSH key for Konstantin's support access (only if user agreed):
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... konstantin@sokkosai.com" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## Phase 8 — Apply client-specific overlay (if exists)

Check if there's an overlay folder for this machine:
```bash
# The Claude Code prompt that launched this should know the overlay path
# e.g. /x/0089a9d3/install.sh
```

If overlay `install.sh` exists, execute it. It contains client-specific
extras (e.g. iused.nl monitor, custom skills).

---

## Phase 9 — Smoke tests

```bash
# 9.1 OpenClaw is alive
openclaw status | grep -E "state|provider"

# 9.2 Send test message via Telegram
openclaw message send --channel telegram --target "<user-id>" \
  --message "Final smoke test ✅"

# 9.3 SSH from external (user verifies on phone or other device)
echo "Try: ssh $(whoami)@$(tailscale ip -4) from another device"

# 9.4 If iused.nl monitor installed, run once manually
test -f ~/.openclaw/workspace/toolbox/scripts/iused-monitor.py && \
  python3 ~/.openclaw/workspace/toolbox/scripts/iused-monitor.py
```

---

## Phase 10 — Final report

Print a summary card to the user:

```
═══════════════════════════════════════
✅ OpenClaw installation complete

Hostname:      $(hostname -s)
Tailscale IP:  $(tailscale ip -4)
Telegram bot:  @<bot_username>
AI provider:   <ChatGPT Plus | OpenAI API | Gemini Free>
Workspace:     ~/.openclaw/workspace/

Remote support:
  ssh $(whoami)@$(tailscale ip -4)

Logs:
  tail -f ~/.openclaw/gateway.log

If anything stops working:
  WhatsApp: +31 6 13608863
═══════════════════════════════════════
```

---

## Failure mode

If any phase fails twice, STOP and:
1. Print the exact step that failed
2. Print the last 30 lines of relevant log
3. Tell user: "Please send a screenshot of this output to +31 6 13608863 via WhatsApp"
4. Exit without attempting cleanup

---

## Constraints

- NEVER write API keys to git-tracked files
- NEVER touch files outside `~/.openclaw/` and standard `/usr/local/`, `/opt/homebrew/`
- NEVER run `rm -rf` on user home dir without explicit confirmation
- NEVER skip Phase 9 smoke tests
- If user asks you to skip a phase, ask why before agreeing

#!/usr/bin/env bash
# Purpose: One-shot bootstrap that hands control to Claude Code for OpenClaw install.
# Usage: curl -fsSL https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main/setup/bootstrap.sh | bash
# Or:    curl ... | bash -s -- /x/<slug>  (with client overlay)

set -euo pipefail

OVERLAY_PATH="${1:-}"
KIT_BASE="https://raw.githubusercontent.com/7SoKKoS7/oc-kit/main"

log() { printf "\033[1;36m[bootstrap]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[bootstrap ERR]\033[0m %s\n" "$*" >&2; exit 1; }

# ---------- Pre-flight ----------
log "macOS version check..."
sw_vers -productVersion | awk -F. '{ if ($1 < 14) { print "Need macOS 14+"; exit 1 } }' \
  || err "macOS too old (need 14+)"

log "Homebrew check..."
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || err "Homebrew install failed"
fi

log "Installing core dependencies..."
brew install -q python@3.11 node jq tailscale git 2>&1 | tail -3

# ---------- Claude Code install ----------
log "Installing Claude Code CLI..."
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | sh || err "Claude Code install failed"
fi
log "Claude Code version: $(claude --version 2>&1 | head -1)"

# ---------- Hand off to Claude Code ----------
INSTALL_URL="$KIT_BASE/setup/INSTALL.md"
if [[ -n "$OVERLAY_PATH" ]]; then
  OVERLAY_URL="$KIT_BASE${OVERLAY_PATH}/install.sh"
  log "Client overlay: $OVERLAY_URL"
fi

cat <<EOF

═══════════════════════════════════════════════════════════════
✅ Bootstrap complete. Next step: log into Claude Code.

Run:
  claude

When prompted, paste this super-prompt (one line):

  Read and execute every step in $INSTALL_URL on this Mac.
  Ask me for inputs when needed. If a step fails twice, stop.${OVERLAY_PATH:+
  After phase 7, also execute the overlay at $OVERLAY_URL}

═══════════════════════════════════════════════════════════════
EOF

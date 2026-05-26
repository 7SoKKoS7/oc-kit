#!/usr/bin/env bash
# Purpose: Remove Claude Code installation traces after assisted install session.
# Run on client's Mac AFTER OpenClaw is fully set up.
# Removes auth, config, cache, and history. Does NOT remove OpenClaw itself.

set -euo pipefail

log() { printf "\033[1;36m[cleanup]\033[0m %s\n" "$*"; }

log "Logging out of Claude Code..."
claude logout 2>/dev/null || true

log "Removing Claude Code config..."
rm -rf ~/.claude/ 2>/dev/null || true
rm -rf ~/Library/Caches/com.anthropic.claude-code 2>/dev/null || true
rm -rf ~/Library/Application\ Support/Claude 2>/dev/null || true

log "Removing shell PATH/alias entries..."
for rc in ~/.zshrc ~/.bash_profile ~/.profile; do
  [[ -f "$rc" ]] && sed -i '' '/claude/Id' "$rc" 2>/dev/null || true
done

log "Verifying..."
if [[ -d ~/.claude ]]; then
  log "⚠️  ~/.claude still exists — manual removal needed"
else
  log "✅ ~/.claude removed"
fi

if command -v claude >/dev/null 2>&1; then
  log "⚠️  'claude' command still in PATH at $(command -v claude)"
  log "Run: brew uninstall claude-code  (if installed via brew)"
else
  log "✅ 'claude' command not found in PATH"
fi

log "Clearing shell history (current session)..."
history -c 2>/dev/null || true
rm ~/.zsh_history ~/.bash_history 2>/dev/null || true

log "Done. Disconnect RustDesk now."

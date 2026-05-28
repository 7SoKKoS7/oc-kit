#!/usr/bin/env bash
# Purpose: Remove Claude Code installation traces after assisted install session.
# Run on client's Mac AFTER OpenClaw is fully set up.
# Removes auth, config, cache, install PATH entries. Does NOT remove OpenClaw itself.
#
# Conservative policy:
# - Surgical sed patterns (only Claude Code installer PATH/alias lines, not arbitrary "claude" mentions)
# - Does NOT delete shell history files (only clears current-session history)
# - Always idempotent — safe to re-run

set -euo pipefail

log() { printf "\033[1;36m[cleanup]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[cleanup]\033[0m %s\n" "$*"; }

# 1. Logout (best-effort — claude may already be gone)
log "Logging out of Claude Code..."
claude logout 2>/dev/null || true

# 2. Remove config + cache directories
log "Removing Claude Code config + cache..."
rm -rf ~/.claude/ 2>/dev/null || true
rm -rf ~/Library/Caches/com.anthropic.claude-code 2>/dev/null || true
rm -rf ~/Library/Application\ Support/Claude 2>/dev/null || true
rm -rf ~/.local/share/claude 2>/dev/null || true

# 3. Remove SHELL RC entries — surgical patterns only
# Only delete lines matching Claude Code installer's signature, not arbitrary "claude" mentions.
log "Removing Claude Code install lines from shell rc files (surgical)..."
for rc in ~/.zshrc ~/.bash_profile ~/.profile ~/.bashrc; do
  [[ -f "$rc" ]] || continue
  # Backup before edit (Mark can restore if anything goes wrong)
  cp "$rc" "$rc.pre-claude-cleanup.bak"
  # Patterns to remove:
  #   - PATH lines containing .local/share/claude, .claude/bin, or claude-code
  #   - alias lines for claude
  #   - Source/eval lines pointing to claude installer
  sed -i '' \
    -e '/^export PATH=.*\.local\/share\/claude/d' \
    -e '/^export PATH=.*\.claude\/bin/d' \
    -e '/^export PATH=.*claude-code/d' \
    -e '/^alias claude=/d' \
    -e '/source.*\.local\/share\/claude/d' \
    -e '/eval.*\.local\/share\/claude/d' \
    "$rc" 2>/dev/null || true
done

# 4. Verify removal
log "Verifying..."
if [[ -d ~/.claude ]]; then
  warn "⚠️  ~/.claude still exists — manual removal needed"
else
  log "✅ ~/.claude removed"
fi

if [[ -d ~/.local/share/claude ]]; then
  warn "⚠️  ~/.local/share/claude still exists — manual removal needed"
else
  log "✅ ~/.local/share/claude removed"
fi

# Need new shell to verify PATH — check using fresh shell explicitly
if /bin/zsh -lc 'command -v claude' >/dev/null 2>&1; then
  warn "⚠️  'claude' still in PATH — check ~/.zshrc.pre-claude-cleanup.bak for what was kept"
  warn "    Possibly installed via brew: try 'brew uninstall claude-code' or 'brew uninstall anthropic-ai/claude/claude'"
else
  log "✅ 'claude' not in PATH (new shell)"
fi

# 5. Current session history only (not files)
# Konstantin's session commands are flushed; Mark's pre-install history is preserved.
log "Clearing current shell session history..."
history -c 2>/dev/null || true
# Do NOT rm ~/.zsh_history or ~/.bash_history — Mark's prior history is his.

# 6. Backup hint
log ""
log "Backup files created (Mark can review/delete):"
ls -1 ~/.zshrc.pre-claude-cleanup.bak ~/.bash_profile.pre-claude-cleanup.bak ~/.profile.pre-claude-cleanup.bak ~/.bashrc.pre-claude-cleanup.bak 2>/dev/null | sed 's/^/  /'

log "Done. Disconnect RustDesk now."

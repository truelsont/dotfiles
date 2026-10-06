#!/usr/bin/env bash
# Re-link dotfiles and optionally upgrade tools.
# Usage: ./scripts/sync.sh [--update]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE=false

for arg in "$@"; do
    if [[ "$arg" == "--update" ]]; then
        UPDATE=true
    else
        echo "unknown arg: $arg" >&2; exit 1
    fi
done

log()  { printf '[sync] %s\n' "$*"; }
step() { printf '\n══ %s ══\n' "$*"; }

# ── Bootstrap: delegate to full installer if tools are missing ─
if ! command -v brew &>/dev/null || ! command -v nvim &>/dev/null || ! command -v tmux &>/dev/null; then
    log "missing core tools — running full installer"
    exec bash "$DOTFILES/scripts/install_macos.sh"
fi

# ── Symlinks ──────────────────────────────────────────────────
step "symlinking dotfiles"

symlink() {
    local src="$DOTFILES/$1" dst="$HOME/$2"
    if [[ ! -e "$src" ]]; then
        log "SKIP  $1 (not found in dotfiles)"
        return
    fi
    if [[ -d "$dst" && ! -L "$dst" ]]; then
        log "ERROR $2 is a real directory — remove it manually before linking"
        return 1
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    log "linked ~/$2"
}

symlink "tmux/tmux.conf"        ".tmux.conf"
symlink "nvim/init.lua"         ".config/nvim/init.lua"
symlink "shell/zshrc_macos"     ".zshrc"
symlink "shell/zshrc_common"    ".zshrc_common"
symlink "claude/CLAUDE.md"      ".claude/CLAUDE.md"
symlink "claude/settings.json"  ".claude/settings.json"

# ── System-wide tmux config ───────────────────────────────────
step "copying tmux.conf to /etc/tmux.conf"
if sudo cp "$DOTFILES/tmux/tmux.conf" /etc/tmux.conf; then
    log "copied to /etc/tmux.conf"
else
    log "SKIP /etc/tmux.conf (sudo failed — run manually if needed)"
fi

# ── Optional updates ──────────────────────────────────────────
if [[ "$UPDATE" == true ]]; then
    step "upgrading brew packages"
    # scoped to what we install — avoids upgrading unrelated global packages
    brew upgrade \
        gcc make cmake git curl wget htop btop tmux \
        ripgrep fd fzf bat jq tree zsh node sqlite neovim gh \
        2>/dev/null || true

    step "updating Oh My Zsh"
    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        git -C "$HOME/.oh-my-zsh" pull --ff-only \
            || log "omz pull skipped (local changes or already up to date)"
    else
        log "Oh My Zsh not found — skipping"
    fi

    step "updating zsh plugins"
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ -d "$ZSH_CUSTOM/plugins" ]]; then
        for plugin_dir in "$ZSH_CUSTOM/plugins"/*/; do
            if [[ -d "$plugin_dir/.git" ]]; then
                log "pulling $(basename "$plugin_dir")"
                git -C "$plugin_dir" pull --ff-only \
                    || log "  skipped $(basename "$plugin_dir") (local changes)"
            fi
        done
    else
        log "no zsh plugins dir found — skipping"
    fi
fi

step "done"
if [[ "$UPDATE" != true ]]; then
    log "tip: run with --update to also upgrade brew packages and plugins"
fi
log "run 'exec zsh' to reload your shell"

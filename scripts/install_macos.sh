#!/usr/bin/env bash
# ============================================================
# install_macos.sh — Reproducible dev setup for macOS
# ============================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { echo "[install] $*"; }
step() { echo; echo "══ $* ══"; }

# ── Xcode Command Line Tools ─────────────────────────────────
step "Ensuring Xcode CLT"
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    log "Install Xcode CLT when prompted, then re-run this script"
    exit 1
fi

# ── Homebrew ─────────────────────────────────────────────────
step "Installing Homebrew"
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null \
        || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
    log "Homebrew installed"
else
    log "Homebrew already installed: $(brew --version | head -1)"
fi

# ── Core CLI tools ───────────────────────────────────────────
step "Installing core tools via brew"
brew install \
    gcc make cmake \
    git curl wget \
    htop btop \
    tmux \
    ripgrep fd fzf bat \
    jq tree \
    zsh \
    node \
    sqlite \
    neovim \
    gh

# macOS-specific fzf setup
$(brew --prefix)/opt/fzf/install --all --no-update-rc 2>/dev/null || true

# ── uv (Python package/project manager) ──────────────────────
step "Installing uv"
if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    log "uv installed"
else
    log "uv already installed: $(uv --version)"
fi

# ── Rust & cargo ─────────────────────────────────────────────
step "Installing Rust"
if ! command -v cargo &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    source "$HOME/.cargo/env"
    log "Rust installed"
else
    log "Rust already installed: $(rustc --version)"
fi

# ── Go ───────────────────────────────────────────────────────
step "Installing Go"
if ! command -v go &>/dev/null; then
    brew install go
    log "Go installed"
else
    log "Go already installed: $(go version)"
fi

# ── Docker Desktop ───────────────────────────────────────────
step "Installing Docker Desktop"
if ! command -v docker &>/dev/null; then
    brew install --cask docker
    log "Docker Desktop installed — open it to complete setup"
else
    log "Docker already installed: $(docker --version)"
fi

# ── Oh My Zsh ────────────────────────────────────────────────
step "Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh My Zsh installed"
else
    log "Oh My Zsh already installed"
fi

# ── Symlink dotfiles ─────────────────────────────────────────
step "Symlinking dotfiles"
symlink() {
    local src="$DOTFILES_DIR/$1"
    local dst="$HOME/$2"
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
        log "Linked $dst -> $src"
    fi
}

symlink "tmux/tmux.conf"     ".tmux.conf"
symlink "nvim/init.lua"      ".config/nvim/init.lua"
symlink "shell/zshrc_macos"  ".zshrc"

step "Done! Restart your shell or run: source ~/.zshrc"

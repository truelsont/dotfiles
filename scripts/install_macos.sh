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

# tree-sitter CLI (needed for nvim-treesitter to compile parsers like latex)
npm install -g tree-sitter-cli

# macOS-specific fzf setup
if [ ! -f ~/.fzf.zsh ]; then
    $(brew --prefix)/opt/fzf/install --all --no-update-rc 2>/dev/null || true
fi

# ── GitHub CLI auth ───────────────────────────────────────────
step "Authenticating GitHub CLI"
if ! gh auth status &>/dev/null; then
    gh auth login
else
    log "Already authenticated: $(gh auth status 2>&1 | grep 'Logged in' | xargs)"
fi

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

# ── Zsh plugins (external) ──────────────────────────────────
step "Installing zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log "zsh-autosuggestions installed"
else
    log "zsh-autosuggestions already installed"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log "zsh-syntax-highlighting installed"
else
    log "zsh-syntax-highlighting already installed"
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

symlink "tmux/tmux.conf"        ".tmux.conf"
symlink "nvim/init.lua"         ".config/nvim/init.lua"
symlink "shell/zshrc_macos"     ".zshrc"
symlink "shell/zshrc_common"    ".zshrc_common"
symlink "claude/CLAUDE.md"      ".claude/CLAUDE.md"
symlink "claude/settings.json"  ".claude/settings.json"

# ── Default shell ────────────────────────────────────────────
# Without this, a login shell of bash will try to parse the new
# zsh-syntax ~/.zshrc and fail (e.g. unexpected EOF), and Terminal
# sessions open into a shell that never loads our config.
step "Setting zsh as default shell"
TARGET_ZSH="$(command -v zsh)"
if ! grep -qx "$TARGET_ZSH" /etc/shells; then
    echo "$TARGET_ZSH" | sudo tee -a /etc/shells >/dev/null
    log "Added $TARGET_ZSH to /etc/shells"
fi
CURRENT_SHELL="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
if [ "$CURRENT_SHELL" != "$TARGET_ZSH" ]; then
    log "Changing default shell from $CURRENT_SHELL to $TARGET_ZSH (will prompt for password)"
    chsh -s "$TARGET_ZSH" || log "chsh failed — run manually: chsh -s $TARGET_ZSH"
else
    log "Default shell already $TARGET_ZSH"
fi

step "Done! Open a NEW terminal window (so login shell is zsh) or run: exec zsh"

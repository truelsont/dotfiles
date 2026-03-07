#!/usr/bin/env bash
# ============================================================
# install_linux.sh — Reproducible dev setup for Ubuntu/Debian
# ============================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log()  { echo "[install] $*"; }
step() { echo; echo "══ $* ══"; }

# ── System packages ──────────────────────────────────────────
step "Updating apt"
sudo apt update

step "Installing core tools"
sudo apt install -y \
    build-essential gcc g++ make cmake \
    git curl wget unzip zip \
    htop btop \
    tmux \
    ripgrep fd-find fzf bat \
    jq tree \
    zsh \
    python3 python3-pip python3-venv \
    nodejs npm \
    sqlite3 \
    xclip \
    ca-certificates gnupg

# ── Neovim (latest stable via AppImage or PPA) ───────────────
step "Installing Neovim"
if ! command -v nvim &>/dev/null; then
    NVIM_VER=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
        | grep '"tag_name"' | cut -d '"' -f4)
    curl -Lo /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/${NVIM_VER}/nvim-linux-x86_64.tar.gz"
    sudo tar -C /opt -xzf /tmp/nvim.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm /tmp/nvim.tar.gz
    log "Neovim ${NVIM_VER} installed"
else
    log "Neovim already installed: $(nvim --version | head -1)"
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
    GO_VER=$(curl -s "https://go.dev/VERSION?m=text" | head -1)
    curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    log "Go ${GO_VER} installed"
else
    log "Go already installed: $(go version)"
fi

# ── Docker ───────────────────────────────────────────────────
step "Installing Docker"
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    log "Docker installed (log out/in for group to take effect)"
else
    log "Docker already installed: $(docker --version)"
fi

# ── GitHub CLI ───────────────────────────────────────────────
step "Installing GitHub CLI"
if ! command -v gh &>/dev/null; then
    if [ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
            https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    fi
    sudo apt update && sudo apt install -y gh
    log "GitHub CLI installed"
else
    log "gh already installed: $(gh --version | head -1)"
fi

step "Authenticating GitHub CLI"
if ! gh auth status &>/dev/null; then
    gh auth login
else
    log "Already authenticated: $(gh auth status 2>&1 | grep 'Logged in' | xargs)"
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

symlink "tmux/tmux.conf"       ".tmux.conf"
symlink "nvim/init.lua"        ".config/nvim/init.lua"
symlink "shell/zshrc_linux"    ".zshrc"
symlink "claude/CLAUDE.md"     ".claude/CLAUDE.md"
symlink "claude/settings.json" ".claude/settings.json"

step "Done! Restart your shell or run: source ~/.zshrc"
echo "Note: log out and back in for Docker group changes to take effect."

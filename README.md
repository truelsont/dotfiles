# dotfiles

Reproducible dev environment setup for Linux (Ubuntu/Debian) and macOS.

## What's included

| Tool | Config |
|------|--------|
| tmux | `tmux/tmux.conf` |
| Neovim | `nvim/init.lua` (lazy.nvim, LSP, Telescope, Treesitter) |
| Zsh | `shell/zshrc_linux` / `shell/zshrc_macos` |

## Install

### Linux (Ubuntu/Debian)
```bash
git clone git@github.com:truelsont/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash scripts/install_linux.sh
```

### macOS
```bash
git clone git@github.com:truelsont/dotfiles.git ~/dotfiles
cd ~/dotfiles && bash scripts/install_macos.sh
```

## What gets installed

- **Build tools**: gcc, g++, cmake, make
- **Neovim**: latest stable + LSP (pyright, clangd, ts_ls, lua_ls)
- **Python**: uv (package/project manager)
- **Rust**: rustup + cargo
- **Go**: latest stable
- **CLI tools**: fzf, ripgrep, fd, bat, btop/htop, jq, tree
- **Shell**: Oh My Zsh + autosuggestions + syntax highlighting
- **Docker**: Docker Engine (Linux) / Docker Desktop (macOS)
- **GitHub CLI**: gh

## Neovim keymaps

| Key | Action |
|-----|--------|
| `<Space>ff` | Find files (Telescope) |
| `<Space>fg` | Live grep |
| `<Space>t` | Toggle file tree |
| `gd` | Go to definition |
| `K` | Hover docs |
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action |
| `<Space>f` | Format file |

## tmux keymaps

| Key | Action |
|-----|--------|
| `prefix \|` | Split horizontal |
| `prefix -` | Split vertical |
| `prefix h/j/k/l` | Navigate panes |
| `prefix r` | Reload config |
| `M-h / M-l` | Previous/next window |

#!/usr/bin/env bash
# dotfiles/install.sh — Local bootstrap: install tools + symlink all configs.
#
# Installs the CLI tools the configs expect (fish, starship, tmux, yazi, plus
# the modern coreutils replacements eza/bat/fd/ripgrep/fzf/zoxide/lazygit),
# makes fish the login shell, and symlinks every config into ~/.config (and ~).
# Idempotent — safe to re-run to pull in new dotfiles.
#
# Usage:
#   cd ~/dotfiles && bash install.sh
#   DOTFILES_SET_SHELL=0 bash install.sh   # install + link, but don't chsh
#
# On Linux it installs via the system package manager (apt/dnf/pacman/zypper/
# apk) and needs sudo for that; on macOS it uses Homebrew. Tools that can't be
# installed just warn — config symlinking always proceeds.

set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

log()  { printf "\033[1;34m[*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }

# sudo wrapper — empty when root, skipped when unavailable.
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

# ─── Package manager detection (Linux) ──────────────────────────────────────
PM=""
for c in apt-get dnf pacman zypper apk; do
    if command -v "$c" >/dev/null 2>&1; then PM="$c"; break; fi
done

pm_update() {
    case "$PM" in
        apt-get) $SUDO apt-get update -qq ;;
        dnf)     $SUDO dnf -q makecache || true ;;
        pacman)  $SUDO pacman -Sy --noconfirm >/dev/null ;;
        zypper)  $SUDO zypper -q refresh || true ;;
        apk)     $SUDO apk update -q || true ;;
    esac
}

pm_install() {
    case "$PM" in
        apt-get) $SUDO apt-get install -y -qq "$1" ;;
        dnf)     $SUDO dnf install -y -q "$1" ;;
        pacman)  $SUDO pacman -S --noconfirm --needed "$1" >/dev/null ;;
        zypper)  $SUDO zypper -q install -y "$1" ;;
        apk)     $SUDO apk add -q "$1" ;;
        *)       return 1 ;;
    esac
}

# Best-effort install of one logical tool (trying alternate package names).
# Always returns 0 — a missing tool warns but never aborts the script.
try_install() {
    local tool="$1"; shift
    local names=("$@")
    [ ${#names[@]} -eq 0 ] && names=("$tool")
    command -v "$tool" >/dev/null 2>&1 && return 0
    for n in "${names[@]}"; do
        if pm_install "$n" >/dev/null 2>&1; then
            ok "installed $tool ($n)"
            return 0
        fi
    done
    warn "could not install $tool (install it manually)"
    return 0
}

install_packages() {
    # macOS → Homebrew
    if [ "$(uname)" = "Darwin" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            warn "Homebrew not found — install from https://brew.sh, then re-run"
            return 0
        fi
        log "Installing tools via Homebrew..."
        for f in fish starship tmux eza bat fd ripgrep fzf zoxide yazi lazygit; do
            if brew list "$f" >/dev/null 2>&1; then
                :
            elif brew install "$f" >/dev/null 2>&1; then
                ok "installed $f"
            else
                warn "could not install $f via brew"
            fi
        done
        return 0
    fi

    # Linux → system package manager
    if [ -z "$PM" ]; then
        warn "No known package manager — install tools manually."
        return 0
    fi
    if [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ]; then
        warn "No root/sudo — skipping package installation."
        return 0
    fi

    log "Refreshing package index..."
    pm_update || warn "package index refresh failed (continuing)"

    log "Installing tools..."
    try_install git
    try_install curl
    try_install fish
    try_install tmux
    try_install unzip
    try_install eza
    try_install bat     bat batcat
    try_install fd      fd-find fd
    try_install ripgrep ripgrep
    try_install fzf
    try_install zoxide
    try_install yazi
    try_install lazygit

    # Debian names bat -> batcat and fd -> fdfind; the configs call bat/fd, so
    # expose the expected names on PATH.
    mkdir -p "$HOME/.local/bin"
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; ok "linked bat -> batcat"
    fi
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; ok "linked fd -> fdfind"
    fi

    # Starship isn't packaged everywhere — use the official installer (no sudo).
    if ! command -v starship >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
        log "Installing starship..."
        mkdir -p "$HOME/.local/bin"
        if curl -fsSL https://starship.rs/install/install.sh \
            | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1; then
            ok "starship installed"
        else
            warn "starship install failed (prompt falls back to default)"
        fi
    fi
}

# Make fish the login shell (adds it to /etc/shells if needed).
set_default_shell() {
    command -v fish >/dev/null 2>&1 || { warn "fish not installed — skipping default shell"; return 0; }
    local fish_bin
    fish_bin="$(command -v fish)"
    if [ "${SHELL:-}" = "$fish_bin" ]; then
        ok "fish is already the default shell"
        return 0
    fi
    grep -qxF "$fish_bin" /etc/shells 2>/dev/null || \
        echo "$fish_bin" | $SUDO tee -a /etc/shells >/dev/null 2>&1 || true
    if chsh -s "$fish_bin" >/dev/null 2>&1; then
        ok "default shell → fish (log out and back in to apply)"
    else
        warn "could not chsh — run manually: chsh -s $fish_bin"
    fi
}

link() {
    local src="$DOTFILES/$1"
    local dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  backup: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  linked: $dst → $src"
}

echo "=== Installing tools ==="
install_packages

echo "=== Fish ==="
link "fish/config.fish" "$HOME/.config/fish/config.fish"

echo "=== Starship ==="
link "starship/starship.toml" "$HOME/.config/starship.toml"

echo "=== Ghostty ==="
link "ghostty/config" "$HOME/.config/ghostty/config"

echo "=== Yazi ==="
link "yazi/init.lua" "$HOME/.config/yazi/init.lua"
link "yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
link "yazi/theme.toml" "$HOME/.config/yazi/theme.toml"
link "yazi/package.toml" "$HOME/.config/yazi/package.toml"

echo "=== Lazygit ==="
if [ -f "$DOTFILES/lazygit/config.yml" ]; then
    link "lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
fi

echo "=== Tmux ==="
if [ -f "$DOTFILES/tmux/tmux.conf" ]; then
    link "tmux/tmux.conf" "$HOME/.tmux.conf"
fi

echo "=== Default shell ==="
# Skippable via DOTFILES_SET_SHELL=0 (used by deploy-server.sh --no-shell).
if [ "${DOTFILES_SET_SHELL:-1}" = "1" ]; then
    set_default_shell
else
    echo "  skipped (DOTFILES_SET_SHELL=0)"
fi

echo ""
ok "Done. Restart your shell or run: source ~/.config/fish/config.fish"

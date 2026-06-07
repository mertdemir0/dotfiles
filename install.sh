#!/usr/bin/env bash
# dotfiles/install.sh — Symlink all configs
# Usage: cd ~/Desktop/dotfiles && bash install.sh

set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# sudo wrapper — empty when root, skipped when unavailable.
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
fi

# Install fish via whatever package manager this machine has.
install_fish() {
    if command -v fish >/dev/null 2>&1; then
        echo "  fish already installed"
        return 0
    fi
    echo "  installing fish..."
    if [ "$(uname)" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            brew install fish
        else
            echo "  ! Homebrew not found — install fish manually: https://fishshell.com"
            return 1
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq && $SUDO apt-get install -y fish
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y fish
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --noconfirm --needed fish
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper install -y fish
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add fish
    else
        echo "  ! No known package manager — install fish manually: https://fishshell.com"
        return 1
    fi
}

# Make fish the login shell (adds it to /etc/shells if needed).
set_default_shell() {
    command -v fish >/dev/null 2>&1 || { echo "  ! fish not installed — skipping default shell"; return 0; }
    local fish_bin
    fish_bin="$(command -v fish)"
    if [ "${SHELL:-}" = "$fish_bin" ]; then
        echo "  fish is already the default shell"
        return 0
    fi
    grep -qxF "$fish_bin" /etc/shells 2>/dev/null || \
        echo "$fish_bin" | $SUDO tee -a /etc/shells >/dev/null 2>&1 || true
    if chsh -s "$fish_bin" >/dev/null 2>&1; then
        echo "  default shell → fish (log out and back in to apply)"
    else
        echo "  ! could not chsh — run manually: chsh -s $fish_bin"
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

echo "=== Fish ==="
install_fish || echo "  ! fish install failed — continuing with config symlink"
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
echo "Done. Restart your shell or run: source ~/.config/fish/config.fish"

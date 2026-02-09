#!/usr/bin/env bash
# dotfiles/install.sh — Symlink all configs
# Usage: cd ~/Desktop/dotfiles && bash install.sh

set -e
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

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

echo ""
echo "Done. Restart your shell or run: source ~/.config/fish/config.fish"

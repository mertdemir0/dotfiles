#!/usr/bin/env bash
# deploy-server.sh — Bootstrap a fresh server with these dotfiles.
#
# SSHes into a single host, installs the core CLI tools the configs expect
# (fish, starship, tmux, yazi, plus the modern coreutils replacements like
# eza/bat/fd/ripgrep), clones this dotfiles repo, and runs install.sh to
# symlink every config. Everything is idempotent, so it is safe to re-run
# after a server is rebuilt or to pull in new dotfiles.
#
# By default it also makes fish the remote user's login shell.
#
# Usage:
#   ./scripts/deploy-server.sh user@host
#   ./scripts/deploy-server.sh user@host --no-shell        # keep current login shell
#   ./scripts/deploy-server.sh user@host --branch dev      # deploy a branch
#   ./scripts/deploy-server.sh user@host --repo URL        # override repo URL
#
# Requires key-based SSH access to the target. The remote user needs sudo
# (passwordless preferred) to install packages; if sudo is unavailable the
# script still links configs but skips package installation.

set -euo pipefail

# ─── Defaults ───────────────────────────────────────────────────────────────
REPO_URL="https://github.com/mertdemir0/dotfiles.git"
BRANCH="master"
DO_SHELL=1
TARGET=""

# ─── Pretty logging (local) ─────────────────────────────────────────────────
log()  { printf "\033[1;34m[*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[✗]\033[0m %s\n" "$*" >&2; }

usage() {
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

# ─── Parse args ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)   usage 0 ;;
        --shell)     DO_SHELL=1; shift ;;   # back-compat: now the default
        --no-shell)  DO_SHELL=0; shift ;;
        --branch)    BRANCH="${2:?--branch needs a value}"; shift 2 ;;
        --repo)      REPO_URL="${2:?--repo needs a value}"; shift 2 ;;
        -*)          err "Unknown option: $1"; usage 1 ;;
        *)
            if [[ -n "$TARGET" ]]; then
                err "Only one host is supported per run (got '$TARGET' and '$1')."
                exit 1
            fi
            TARGET="$1"; shift ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    err "Missing target host."
    usage 1
fi

if ! command -v ssh >/dev/null 2>&1; then
    err "ssh is not installed locally."
    exit 1
fi

# ─── Connectivity check ─────────────────────────────────────────────────────
log "Testing SSH connection to ${TARGET}..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$TARGET" true 2>/dev/null; then
    err "Cannot reach ${TARGET} over SSH (need key-based auth / reachable host)."
    exit 1
fi
ok "Connected to ${TARGET}."

# ─── Remote bootstrap ───────────────────────────────────────────────────────
# Runs on the target. Args: $1=repo url  $2=branch  $3=do_shell(0/1)
log "Bootstrapping ${TARGET} (branch: ${BRANCH})..."
ssh "$TARGET" 'bash -s' -- "$REPO_URL" "$BRANCH" "$DO_SHELL" <<'REMOTE'
set -euo pipefail

REPO_URL="$1"
BRANCH="$2"
DO_SHELL="$3"
REPO_DIR="$HOME/dotfiles"

log()  { printf "\033[1;34m  [*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m  [✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m  [!]\033[0m %s\n" "$*"; }

# sudo wrapper — empty when already root, skipped if sudo is missing.
SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        warn "Not root and no sudo — will skip package installation."
    fi
fi

# ─── Detect package manager ────────────────────────────────────────────────
PM=""
for c in apt-get dnf pacman zypper apk; do
    if command -v "$c" >/dev/null 2>&1; then PM="$c"; break; fi
done
[[ -n "$PM" ]] && ok "Package manager: $PM" || warn "No known package manager found."

pm_update() {
    case "$PM" in
        apt-get) $SUDO apt-get update -qq ;;
        dnf)     $SUDO dnf -q makecache  || true ;;
        pacman)  $SUDO pacman -Sy --noconfirm >/dev/null ;;
        zypper)  $SUDO zypper -q refresh  || true ;;
        apk)     $SUDO apk update -q      || true ;;
    esac
}

# Install one package, tolerating failure (not every distro packages every tool).
pm_install() {
    local pkg="$1"
    case "$PM" in
        apt-get) $SUDO apt-get install -y -qq "$pkg" ;;
        dnf)     $SUDO dnf install -y -q "$pkg" ;;
        pacman)  $SUDO pacman -S --noconfirm --needed "$pkg" >/dev/null ;;
        zypper)  $SUDO zypper -q install -y "$pkg" ;;
        apk)     $SUDO apk add -q "$pkg" ;;
        *)       return 1 ;;
    esac
}

try_install() {
    # Map a logical tool name to per-distro package names, install best effort.
    local tool="$1"; shift
    local names=("$@")
    [[ ${#names[@]} -eq 0 ]] && names=("$tool")
    for n in "${names[@]}"; do
        if pm_install "$n" >/dev/null 2>&1; then
            ok "installed $tool ($n)"
            return 0
        fi
    done
    warn "could not install $tool via $PM (may need manual setup)"
    return 1
}

if [[ -n "$PM" && ( "$(id -u)" -eq 0 || -n "$SUDO" ) ]]; then
    log "Refreshing package index..."
    pm_update || warn "package index refresh failed (continuing)"

    log "Installing required tools..."
    try_install git
    try_install curl
    try_install fish
    try_install tmux
    try_install unzip

    log "Installing modern CLI tools (best effort)..."
    # Debian/Ubuntu ship some of these under alternate names.
    try_install eza
    try_install bat       bat batcat
    try_install fd        fd-find fd
    try_install ripgrep   ripgrep
    try_install fzf
    try_install zoxide
    try_install yazi
    try_install lazygit

    # Debian names bat -> batcat and fd -> fdfind; the configs call bat/fd,
    # so expose the expected names on PATH.
    mkdir -p "$HOME/.local/bin"
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        ok "linked bat -> batcat"
    fi
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        ok "linked fd -> fdfind"
    fi
else
    warn "Skipping package installation (no package manager or no privileges)."
fi

# ─── Starship (official installer, no sudo, into ~/.local/bin) ──────────────
if ! command -v starship >/dev/null 2>&1; then
    if command -v curl >/dev/null 2>&1; then
        log "Installing starship..."
        mkdir -p "$HOME/.local/bin"
        if curl -fsSL https://starship.rs/install/install.sh \
            | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1; then
            ok "starship installed"
        else
            warn "starship install failed (prompt will fall back to default)"
        fi
    fi
else
    ok "starship already present"
fi

# ─── Clone / update dotfiles ───────────────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
    warn "git is unavailable — cannot fetch dotfiles. Aborting bootstrap."
    exit 1
fi

if [[ -d "$REPO_DIR/.git" ]]; then
    log "Updating existing dotfiles in $REPO_DIR..."
    git -C "$REPO_DIR" fetch --quiet origin "$BRANCH"
    git -C "$REPO_DIR" checkout --quiet "$BRANCH"
    git -C "$REPO_DIR" pull --quiet --ff-only origin "$BRANCH" || \
        warn "fast-forward pull failed (local changes?) — using existing checkout"
else
    log "Cloning $REPO_URL -> $REPO_DIR..."
    git clone --quiet --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi
ok "dotfiles ready at $REPO_DIR"

# ─── Link configs (install.sh handles fish install + default shell) ────────
# DOTFILES_SET_SHELL drives whether install.sh chsh's to fish, honoring
# --no-shell without duplicating the logic here.
log "Running install.sh..."
DOTFILES_SET_SHELL="$DO_SHELL" bash "$REPO_DIR/install.sh"

ok "Bootstrap complete on $(hostname)."
REMOTE

ok "Deployment to ${TARGET} finished."
echo
log "Next steps:"
echo "    • SSH in and start fish:  ssh ${TARGET} -t fish"
[[ "$DO_SHELL" -eq 1 ]] && echo "    • fish is now the login shell (re-login to apply)"
[[ "$DO_SHELL" -eq 0 ]] && echo "    • Login shell unchanged (--no-shell); set later: chsh -s \$(command -v fish)"
echo "    • Add secrets:            copy fish/secrets.fish.example → ~/.config/fish/secrets.fish"

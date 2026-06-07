#!/usr/bin/env bash
# deploy-server.sh — Bootstrap a server with these dotfiles.
#
# Two modes:
#   • Remote (default): SSH into user@host, install git if needed, clone this
#     repo there, and run install.sh — which installs all the CLI tools the
#     configs expect (fish, starship, tmux, yazi, eza/bat/fd/ripgrep, …) and
#     symlinks every config.
#   • Local (--local):  run install.sh on the CURRENT machine. Use this when
#     you've already cloned the repo onto the box you're setting up (i.e.
#     you're pulling, not pushing).
#
# By default fish is also made the login shell (pass --no-shell to skip).
# Everything is idempotent — safe to re-run to pull in new dotfiles.
#
# Usage:
#   ./scripts/deploy-server.sh --local                # bootstrap THIS machine
#   ./scripts/deploy-server.sh user@host              # remote bootstrap over SSH
#   ./scripts/deploy-server.sh user@host --no-shell   # keep current login shell
#   ./scripts/deploy-server.sh user@host --branch dev # deploy a branch
#   ./scripts/deploy-server.sh user@host --repo URL   # override repo URL
#
# Remote mode needs key-based SSH access; package installation needs sudo on
# the target (passwordless preferred).

set -euo pipefail

# ─── Defaults ───────────────────────────────────────────────────────────────
REPO_URL="https://github.com/mertdemir0/dotfiles.git"
BRANCH="master"
DO_SHELL=1
LOCAL=0
TARGET=""

# ─── Pretty logging (local) ─────────────────────────────────────────────────
log()  { printf "\033[1;34m[*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[✗]\033[0m %s\n" "$*" >&2; }

usage() {
    # Print the leading comment block (everything after the shebang up to the
    # first non-comment line), stripping the "# " prefix.
    awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
    exit "${1:-0}"
}

# ─── Parse args ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)   usage 0 ;;
        --local)     LOCAL=1; shift ;;
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

# ─── Local mode: bootstrap the current machine ──────────────────────────────
if [[ "$LOCAL" -eq 1 ]]; then
    if [[ -n "$TARGET" ]]; then
        err "--local takes no host argument (got '$TARGET')."
        exit 1
    fi
    REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
    if [[ ! -f "$REPO_DIR/install.sh" ]]; then
        err "Cannot find install.sh at $REPO_DIR — run from inside the dotfiles repo."
        exit 1
    fi
    log "Bootstrapping this machine from $REPO_DIR..."
    DOTFILES_SET_SHELL="$DO_SHELL" bash "$REPO_DIR/install.sh"
    ok "Local bootstrap complete."
    exit 0
fi

# ─── Remote mode ────────────────────────────────────────────────────────────
if [[ -z "$TARGET" ]]; then
    err "Missing target host (or pass --local to set up this machine)."
    usage 1
fi

if ! command -v ssh >/dev/null 2>&1; then
    err "ssh is not installed locally."
    exit 1
fi

log "Testing SSH connection to ${TARGET}..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$TARGET" true 2>/dev/null; then
    err "Cannot reach ${TARGET} over SSH (need key-based auth / reachable host)."
    exit 1
fi
ok "Connected to ${TARGET}."

# Remote bootstrap. install.sh does the heavy lifting (tools + links + shell);
# here we only guarantee git exists and the repo is present, then hand off.
# Args: $1=repo url  $2=branch  $3=do_shell(0/1)
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

SUDO=""
if [[ "$(id -u)" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

# git is the one prerequisite we need before install.sh can run (it fetches
# the repo that contains install.sh). Everything else install.sh installs.
if ! command -v git >/dev/null 2>&1; then
    log "Installing git..."
    if   command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update -qq && $SUDO apt-get install -y -qq git || true
    elif command -v dnf     >/dev/null 2>&1; then $SUDO dnf install -y -q git || true
    elif command -v pacman  >/dev/null 2>&1; then $SUDO pacman -S --noconfirm --needed git || true
    elif command -v zypper  >/dev/null 2>&1; then $SUDO zypper -q install -y git || true
    elif command -v apk     >/dev/null 2>&1; then $SUDO apk add -q git || true
    fi
fi
if ! command -v git >/dev/null 2>&1; then
    warn "git unavailable — cannot fetch dotfiles. Aborting."
    exit 1
fi

if [[ -d "$REPO_DIR/.git" ]]; then
    log "Updating dotfiles in $REPO_DIR..."
    git -C "$REPO_DIR" fetch --quiet origin "$BRANCH"
    git -C "$REPO_DIR" checkout --quiet "$BRANCH"
    git -C "$REPO_DIR" pull --quiet --ff-only origin "$BRANCH" || \
        warn "fast-forward pull failed (local changes?) — using existing checkout"
else
    log "Cloning $REPO_URL -> $REPO_DIR..."
    git clone --quiet --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi
ok "dotfiles ready at $REPO_DIR"

log "Running install.sh (installs tools + links configs)..."
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

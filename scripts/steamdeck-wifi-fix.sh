#!/usr/bin/env bash
# steamdeck-wifi-fix.sh
# Fix recurring SteamOS "no secrets provided" wifi error by switching
# NetworkManager's backend from iwd to wpa_supplicant.
#
# SteamOS updates revert the read-only filesystem and can wipe this config,
# so this script is safe to re-run after every system update.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mertdemir0/dotfiles/master/scripts/steamdeck-wifi-fix.sh | bash
# or:
#   chmod +x steamdeck-wifi-fix.sh && ./steamdeck-wifi-fix.sh

set -euo pipefail

CONF_FILE="/etc/NetworkManager/conf.d/wifi_backend.conf"
DESIRED_BACKEND="wpa_supplicant"
READONLY_WAS_ENABLED=0

log()  { printf "\033[1;34m[*]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[✗]\033[0m %s\n" "$*" >&2; }

# ─── Sanity checks ──────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
    err "This script is for SteamOS (Linux) only."
    exit 1
fi

if ! command -v steamos-readonly >/dev/null 2>&1; then
    warn "steamos-readonly not found — not a Steam Deck? Continuing anyway."
fi

if [[ $EUID -ne 0 ]]; then
    log "Re-running with sudo..."
    exec sudo -E bash "$0" "$@"
fi

# ─── Idempotency check ──────────────────────────────────────────────────────
if [[ -f "$CONF_FILE" ]] && grep -q "^wifi.backend=${DESIRED_BACKEND}$" "$CONF_FILE"; then
    if systemctl is-enabled wpa_supplicant >/dev/null 2>&1 \
       && ! systemctl is-enabled iwd >/dev/null 2>&1; then
        ok "Already configured for ${DESIRED_BACKEND}. Nothing to do."
        ok "If wifi is still broken, run: sudo systemctl restart NetworkManager"
        exit 0
    fi
fi

# ─── Disable read-only FS ───────────────────────────────────────────────────
if command -v steamos-readonly >/dev/null 2>&1; then
    if steamos-readonly status 2>/dev/null | grep -qi enabled; then
        log "Disabling read-only filesystem..."
        steamos-readonly disable
        READONLY_WAS_ENABLED=1
        ok "Read-only disabled."
    else
        log "Read-only filesystem already disabled."
    fi
fi

# ─── Write backend config ──────────────────────────────────────────────────
log "Writing ${CONF_FILE}..."
mkdir -p "$(dirname "$CONF_FILE")"
cat > "$CONF_FILE" <<EOF
# Managed by steamdeck-wifi-fix.sh
# Forces NetworkManager to use wpa_supplicant instead of iwd, which has
# known bugs producing "no secrets provided" errors on SteamOS.
[device]
wifi.backend=${DESIRED_BACKEND}
EOF
ok "Config written."

# ─── Service swap ───────────────────────────────────────────────────────────
log "Enabling wpa_supplicant, disabling iwd..."
systemctl enable wpa_supplicant >/dev/null 2>&1 || warn "Could not enable wpa_supplicant"
systemctl disable iwd >/dev/null 2>&1 || true   # iwd may not exist on newer images
systemctl stop iwd >/dev/null 2>&1 || true
ok "Services updated."

# ─── Re-enable read-only ────────────────────────────────────────────────────
if [[ "$READONLY_WAS_ENABLED" -eq 1 ]] && command -v steamos-readonly >/dev/null 2>&1; then
    log "Re-enabling read-only filesystem..."
    steamos-readonly enable
    ok "Read-only re-enabled."
fi

# ─── Restart NetworkManager ────────────────────────────────────────────────
log "Restarting NetworkManager..."
systemctl restart NetworkManager
ok "NetworkManager restarted."

echo
ok "Done. If wifi still fails:"
echo "    1. Reboot:           sudo reboot"
echo "    2. Forget network in Desktop Mode → Wi-Fi tray → right-click → Forget"
echo "    3. Reconnect and re-enter your password fresh"

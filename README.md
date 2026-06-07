# dotfiles

Cross-platform terminal setup — Fish, Starship, tmux, Yazi, Ghostty, and
WezTerm configs, wired together with a single symlink installer.

## Contents

| Path | What it is |
|------|------------|
| `fish/` | Fish shell config, aliases, and a `secrets.fish.example` template |
| `starship/` | Starship prompt theme |
| `tmux/` | tmux config |
| `yazi/` | Yazi file manager (config, theme, keymap, plugins) |
| `ghostty/` | Ghostty terminal config |
| `wezterm/` | WezTerm terminal config |
| `install.sh` | Symlinks every config into `~/.config` (and `~`) |
| `scripts/` | Standalone helper scripts (see below) |

## Local install

Clone, then run the installer. Existing non-symlink configs are backed up to
`*.bak` before being replaced.

```bash
git clone https://github.com/mertdemir0/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Then add your secrets (API keys, etc.):

```bash
cp fish/secrets.fish.example ~/.config/fish/secrets.fish
$EDITOR ~/.config/fish/secrets.fish
```

## Deploy to a server

`scripts/deploy-server.sh` bootstraps a fresh server over SSH: it installs the
CLI tools the configs expect (fish, tmux, starship, eza/bat/fd/ripgrep, …),
clones this repo to `~/dotfiles`, and runs `install.sh`. It's idempotent, so
re-running just pulls the latest dotfiles and re-links.

```bash
./scripts/deploy-server.sh user@host           # bootstrap + link configs
./scripts/deploy-server.sh user@host --shell   # also make fish the login shell
```

| Flag | Effect |
|------|--------|
| `--shell` | `chsh` the remote user to fish (adds it to `/etc/shells` if needed) |
| `--branch <name>` | Deploy a specific branch (default `master`) |
| `--repo <url>` | Override the repo URL |

Requirements: key-based SSH access to the target. Package installation needs
sudo (passwordless preferred); without it the script still links configs but
skips installing packages. Supports apt / dnf / pacman / zypper / apk.

> Tip: the fish config defines `rssh user@host`, which SSHes in and attaches to
> a persistent tmux session (`tmux new-session -A -s main`) — handy for working
> on servers you've deployed to.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-server.sh` | Bootstrap a fresh server with these dotfiles over SSH |
| `scripts/steamdeck-wifi-fix.sh` | Fix SteamOS "no secrets provided" wifi error by switching NetworkManager to wpa_supplicant |

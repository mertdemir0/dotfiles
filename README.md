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

Clone, then run the installer. `install.sh` is a full local bootstrap: it
installs the CLI tools the configs expect (fish, starship, tmux, yazi, plus
eza/bat/fd/ripgrep/fzf/zoxide/lazygit) via your package manager (apt / dnf /
pacman / zypper / apk) or Homebrew, makes fish your login shell, and symlinks
every config. Idempotent — re-run any time to pull in new dotfiles. Existing
non-symlink configs are backed up to `*.bak` first.

```bash
git clone https://github.com/mertdemir0/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

> On Linux, installing packages needs sudo. To skip the login-shell change, run
> `DOTFILES_SET_SHELL=0 bash install.sh`.

Then add your secrets (API keys, etc.):

```bash
cp fish/secrets.fish.example ~/.config/fish/secrets.fish
$EDITOR ~/.config/fish/secrets.fish
```

## Set up a server

Use `scripts/deploy-server.sh`. It has two modes:

**On the server itself** (you've SSH'd in and cloned the repo — "pulling"):

```bash
cd ~/dotfiles
./scripts/deploy-server.sh --local
```

This just runs `install.sh` on the current machine. (Equivalent to
`bash install.sh` — it's here so the same script covers both directions.)

**From your workstation to a remote host** ("pushing" over SSH):

```bash
./scripts/deploy-server.sh user@host              # bootstrap, link, set fish default
./scripts/deploy-server.sh user@host --no-shell   # keep the current login shell
```

Remote mode installs git if missing, clones this repo to `~/dotfiles` on the
target, and runs `install.sh` there — which installs everything else.

| Flag | Effect |
|------|--------|
| `--local` | Bootstrap the current machine instead of a remote host |
| `--no-shell` | Don't change the login shell (default is to `chsh` to fish) |
| `--branch <name>` | Deploy a specific branch (default `master`) |
| `--repo <url>` | Override the repo URL |

Requirements (remote mode): key-based SSH access to the target, and sudo there
for package installation (passwordless preferred); without sudo it still links
configs but skips installing packages.

> Tip: the fish config defines `rssh user@host`, which SSHes in and attaches to
> a persistent tmux session (`tmux new-session -A -s main`) — handy for working
> on servers you've deployed to.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-server.sh` | Bootstrap a fresh server with these dotfiles over SSH |
| `scripts/steamdeck-wifi-fix.sh` | Fix SteamOS "no secrets provided" wifi error by switching NetworkManager to wpa_supplicant |

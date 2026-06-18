# --- Cross-platform Fish Config ---

# Disable greeting
set -g fish_greeting ""

# ================================
# Homebrew
# ================================
if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# ================================
# PATH — shared
# ================================
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.atuin/bin
fish_add_path ~/.lmstudio/bin
fish_add_path ~/.ghcup/bin
fish_add_path ~/.cabal/bin

# ================================
# PATH — macOS only
# ================================
if test (uname) = "Darwin"
    # OrbStack
    if test -d ~/.orbstack/bin
        fish_add_path ~/.orbstack/bin
    end

    # Miniconda
    if test -f ~/miniconda3/bin/conda
        eval ~/miniconda3/bin/conda "shell.fish" "hook" $argv | source
    end

    # Rye
    if test -f ~/.oi/.rye/env
        fish_add_path ~/.oi/.rye/bin
    end
end

# ================================
# PATH — Linux only
# ================================
if test (uname) = "Linux"
    fish_add_path ~/.tnr/bin
    fish_add_path ~/.opencode/bin

    # CUDA
    if test -d /usr/local/cuda-13.0
        fish_add_path /usr/local/cuda-13.0/bin
        set -gx LD_LIBRARY_PATH /usr/local/cuda-13.0/lib64 $LD_LIBRARY_PATH
    end

    # TexLive
    if test -d /usr/local/texlive/2025
        fish_add_path /usr/local/texlive/2025/bin/x86_64-linux
        set -gx MANPATH /usr/local/texlive/2025/texmf-dist/doc/man $MANPATH
        set -gx INFOPATH /usr/local/texlive/2025/texmf-dist/doc/info $INFOPATH
    end

    # SSH agent (GNOME keyring). gnome-keyring-daemon prints bash-style
    # KEY=value lines, so parse them rather than `eval` (which fish can't).
    if test -z "$SSH_AUTH_SOCK"; and command -q gnome-keyring-daemon
        for line in (gnome-keyring-daemon --start --components=secrets,ssh 2>/dev/null)
            set -l kv (string split -m 1 '=' $line)
            test (count $kv) -eq 2; and set -gx $kv[1] $kv[2]
        end
    end
end

# ================================
# fnm (Node version manager)
# ================================
if test -d ~/.local/share/fnm
    fish_add_path ~/.local/share/fnm
    fnm env --use-on-cd --shell fish | source
end

# ================================
# API keys (loaded from separate file)
# ================================
if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

# ================================
# Interactive-only below this point. Non-interactive shells (VS Code's
# startup probe, `ssh host <cmd>`, scripts) keep the PATH/env set above but
# skip aliases, prompt and tool init.
# ================================
status is-interactive; or exit

# ================================
# Modern CLI replacements
# ================================
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons"
alias la="eza -a --icons --group-directories-first"
alias cat="bat --style=auto"
alias find="fd"
alias grep="rg"

# ================================
# Quick navigation
# ================================
alias pp="cd ~/Desktop/Projects"
alias ..="cd .."
alias ...="cd ../.."
alias cls="clear"

# ================================
# Git shortcuts
# ================================
alias g="git"
alias gs="git status"
alias gp="git push"
alias gc="git commit"
alias gd="git diff"
alias gl="git log --oneline --graph -20"
alias lg="lazygit"

# ================================
# Docker
# ================================
alias dc="docker compose"
alias dck="docker stop (docker ps -q)"   # stop all running containers

# ================================
# Python / ML
# ================================
alias py="python3"
alias pip="pip3"
alias jn="jupyter notebook"
alias tb="tensorboard --logdir"

# ================================
# Linux-only aliases
# ================================
if test (uname) = "Linux"
    # Dataiku DSS
    alias dss-start="~/Apps/dataiku/bin/dss start"
    alias dss-stop="~/Apps/dataiku/bin/dss stop"
    alias dss-status="~/Apps/dataiku/bin/dss status"
    alias dss-tail="~/Apps/dataiku/bin/dss tail"

    # H2O
    alias h2o-start="cd ~/Apps/h2o && java -jar h2o.jar"
    alias h2o-cluster="cd ~/Apps/h2o && java -jar h2o.jar -name cluster"
    alias h2o-memory="cd ~/Apps/h2o && java -Xmx32g -jar h2o.jar"

    alias tokui="~/tokui/bin/tokui"
end

# ================================
# Other tools
# ================================
alias y="yazi"

# ================================
# Remote servers — hosts are SSH config aliases (IP/user/key live in
# ~/.ssh/config, never in this repo). See ssh/config.example.
# ================================
# Hetzner box: main + 4 named tmux sessions
alias oc="ssh hetzner -t 'tmux new-session -A -s main'"
alias oc1="ssh hetzner -t 'tmux new-session -A -s s1'"
alias oc2="ssh hetzner -t 'tmux new-session -A -s s2'"
alias oc3="ssh hetzner -t 'tmux new-session -A -s s3'"
alias oc4="ssh hetzner -t 'tmux new-session -A -s s4'"
# pop-os home machine: main + 4 named tmux sessions
alias hm="ssh pop-os -t 'tmux new-session -A -s main'"
alias hm1="ssh pop-os -t 'tmux new-session -A -s s1'"
alias hm2="ssh pop-os -t 'tmux new-session -A -s s2'"
alias hm3="ssh pop-os -t 'tmux new-session -A -s s3'"
alias hm4="ssh pop-os -t 'tmux new-session -A -s s4'"
# Raspberry Pi
alias pi="ssh raspi"

# ================================
# Quick SSH with tmux
# ================================
function rssh --description "SSH and attach to tmux session"
    ssh -t $argv "tmux new-session -A -s main"
end

# ================================
# Init tools
# ================================

# Starship prompt
if command -q starship
    starship init fish | source
end

# Zoxide — replaces `cd` with frecency-aware jumping. Use --cmd cd (not
# `alias cd=z`, which recurses infinitely into zoxide's own cd call).
if command -q zoxide
    zoxide init fish --cmd cd | source
end

# Atuin (smart history)
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# pyenv (Python version manager)
if command -q pyenv
    pyenv init - | source
end

# fzf key bindings (--fish needs fzf ≥ 0.48; redirect so older fzf, which
# doesn't know --fish, fails silently instead of printing an error)
if test -f ~/.fzf/shell/key-bindings.fish
    source ~/.fzf/shell/key-bindings.fish
else if command -q fzf
    fzf --fish 2>/dev/null | source
end

# FZF config
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=16"

# OrbStack shell integration (macOS)
if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end

# Kiro integration
if string match -q "$TERM_PROGRAM" "kiro"; and command -q kiro
    . (kiro --locate-shell-integration-path fish)
end

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

    # SSH agent (GNOME keyring)
    if test -z "$SSH_AUTH_SOCK"
        eval (gnome-keyring-daemon --start --components=secrets,ssh 2>/dev/null)
        set -x SSH_AUTH_SOCK $SSH_AUTH_SOCK
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
# Modern CLI replacements
# ================================
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons"
alias la="eza -a --icons --group-directories-first"
alias cat="bat --style=auto"
alias find="fd"
alias grep="rg"
alias cd="z"

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

    alias tokui="/home/mert/tokui/bin/tokui"
end

# ================================
# Other tools
# ================================
alias y="yazi"

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

# Zoxide
if command -q zoxide
    zoxide init fish | source
end

# Atuin (smart history)
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# fzf key bindings
if test -f ~/.fzf/shell/key-bindings.fish
    source ~/.fzf/shell/key-bindings.fish
else if command -q fzf
    fzf --fish | source 2>/dev/null
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

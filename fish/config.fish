# --- Comfy Fish Config ---

# Disable greeting
set -g fish_greeting ""

# ================================
# PATH
# ================================
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.atuin/bin
fish_add_path ~/.tnr/bin
fish_add_path ~/.cabal/bin
fish_add_path ~/.ghcup/bin
fish_add_path ~/.lmstudio/bin
fish_add_path ~/.opencode/bin
fish_add_path /usr/local/cuda-13.0/bin
fish_add_path /usr/local/texlive/2025/bin/x86_64-linux

# Homebrew
if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# fnm (Node version manager)
if test -d ~/.local/share/fnm
    fish_add_path ~/.local/share/fnm
    fnm env --use-on-cd --shell fish | source
end

# ================================
# Environment variables
# ================================

# CUDA
set -gx LD_LIBRARY_PATH /usr/local/cuda-13.0/lib64 $LD_LIBRARY_PATH

# TexLive
set -gx MANPATH /usr/local/texlive/2025/texmf-dist/doc/man $MANPATH
set -gx INFOPATH /usr/local/texlive/2025/texmf-dist/doc/info $INFOPATH

# API keys (loaded from separate file for safety)
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
# Dataiku DSS
# ================================
alias dss-start="~/Apps/dataiku/bin/dss start"
alias dss-stop="~/Apps/dataiku/bin/dss stop"
alias dss-status="~/Apps/dataiku/bin/dss status"
alias dss-tail="~/Apps/dataiku/bin/dss tail"

# ================================
# H2O
# ================================
alias h2o-start="cd ~/Apps/h2o && java -jar h2o.jar"
alias h2o-cluster="cd ~/Apps/h2o && java -jar h2o.jar -name cluster"
alias h2o-memory="cd ~/Apps/h2o && java -Xmx32g -jar h2o.jar"

# ================================
# Other tools
# ================================
alias tokui="/home/mert/tokui/bin/tokui"
alias y="yazi"

# ================================
# Quick SSH with tmux (for remote work)
# ================================
function rssh --description "SSH and attach to tmux session"
    ssh -t $argv "tmux new-session -A -s main"
end

# ================================
# SSH agent
# ================================
if test -z "$SSH_AUTH_SOCK"
    eval (gnome-keyring-daemon --start --components=secrets,ssh)
    set -x SSH_AUTH_SOCK $SSH_AUTH_SOCK
end

# ================================
# Init tools
# ================================

# Starship prompt
starship init fish | source

# Zoxide
zoxide init fish | source

# Atuin (smart history)
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# fzf key bindings
if test -f ~/.fzf/shell/key-bindings.fish
    source ~/.fzf/shell/key-bindings.fish
end

# FZF config
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --follow --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --color=16"

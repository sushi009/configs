for f in /etc/zshrc /etc/zsh.zshrc; do [[ -f $f ]] && source $f && break; done

HOMEBREW_PREFIX=""
for dir in /opt/homebrew /home/linuxbrew/.linuxbrew; do [[ -d $dir ]] && HOMEBREW_PREFIX=$dir && break; done

export LESS="-F -X -R"
export RUST_BACKTRACE=1
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxdxdxhxhxexex
export LS_COLORS='di=1;34:ln=1;36:so=1;31:pi=1;33:ex=1;32:bd=33:cd=33:su=37:sg=37:tw=34:ow=34'
if [ -n "$HOMEBREW_PREFIX" ]; then
    export PATH="$HOMEBREW_PREFIX/opt/postgresql@18/bin:$HOMEBREW_PREFIX/opt/curl/bin:$HOMEBREW_PREFIX/bin:$PATH"
fi
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.pyenv/shims:$PATH"
export WORDCHARS='*?_-.~=&;!#$%^(){}<>'
export LESSHISTFILE=/dev/null
export EDITOR=vim
export BAT_THEME="Catppuccin Macchiato"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

ulimit -n 4096 # open files limit:

zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select=1
zstyle ':completion:*' use-compctl true
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*' # case insensitive (all), partial-word, substring completion
if type brew &>/dev/null; then
    fpath+=("$HOMEBREW_PREFIX/share/zsh/site-functions")
fi
fpath+=("$HOME/.local/share/zsh/site-functions" "$HOME/.zshrc.d/completions" "$HOME/.zfunc")
export fpath

setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt AUTO_PUSHD
setopt SHARE_HISTORY
unsetopt BEEP
unsetopt NOMATCH

stty start undef stop undef

autoload -Uz compinit && compinit
autoload -Uz colors && colors

bindkey -v
bindkey '^R' history-incremental-search-backward
export KEYTIMEOUT=1

autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

setopt prompt_subst
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' check-for-changes true # slows down the prompt
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' (%b%u%c%m)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c%m)'

# Add git ahead/behind and untracked files information
zstyle ':vcs_info:git*+set-message:*' hooks git-st
+vi-git-st() {
    local ahead behind
    local -a gitstatus upstatus
    local has_status=0

    # Check for untracked files first (escape % as %%)
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]] && \
        git status --porcelain | grep -q '^?? '; then
        gitstatus+=('%%')
    fi

    # Get ahead/behind counts
    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)

    # Build the ahead/behind status string
    (( $ahead )) && upstatus+=("↑${ahead}")
    (( $behind )) && upstatus+=("↓${behind}")

    # Add space before ahead/behind if there are other status indicators (untracked, unstaged, or staged)
    if [[ -n $upstatus ]]; then
        if [[ -n $gitstatus ]] || [[ -n ${hook_com[unstaged]} ]] || [[ -n ${hook_com[staged]} ]]; then
            gitstatus+=(" ${(j::)upstatus}")
        else
            gitstatus+=("${(j::)upstatus}")
        fi
    fi

    # Check if any status indicators will be shown
    [[ -n ${hook_com[unstaged]} ]] || [[ -n ${hook_com[staged]} ]] || [[ -n $gitstatus ]] && has_status=1

    # Prepend space to branch if there are any status indicators
    (( has_status )) && hook_com[branch]+=" "

    # Set the misc (%m) format
    [[ -n $gitstatus ]] && hook_com[misc]="${(j::)gitstatus}"
}

export VIRTUAL_ENV_DISABLE_PROMPT=yes
add-zsh-hook precmd vcs_info
typeset -a precmd_functions
virtualenv_info() { venv_info_0=${VIRTUAL_ENV:+"(${VIRTUAL_ENV:t}) "}; }
precmd_functions+=(virtualenv_info)
auto_activate_venv() {
    # Deactivate if we leave a venv directory
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local parent_dir="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD" != "$parent_dir"* ]]; then
            deactivate
        fi
    fi
    # Activate if .venv exists in current directory
    if [[ -z "$VIRTUAL_ENV" && -d ".venv" && -f ".venv/bin/activate" ]]; then
        source .venv/bin/activate
    fi
}
add-zsh-hook chpwd auto_activate_venv
auto_activate_venv # Also run on shell startup for the initial directory

install_python() {
    local VER="$(pyenv latest -k 3)"
    PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations --with-lto" PYTHON_CFLAGS='-march=native -mtune=native' pyenv install "$VER" -vv
    pyenv global "$VER"
}

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

clear_and_reset() { clear; printf '\e[3J'; zle reset-prompt; }
zle -N clear_and_reset
bindkey '^L' clear_and_reset

source ~/.custom.sh &>/dev/null || true

alias zed=zed-preview
[ "$TERM_PROGRAM" = zed ] && export EDITOR="zed-preview --wait" || true

export GPG_TTY="${TTY:-"$(tty)"}"

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    export PKG_CONFIG_PATH=/home/linuxbrew/.linuxbrew/lib/pkgconfig
    export LD_LIBRARY_PATH=/home/linuxbrew/.linuxbrew/lib
fi

alias ls="ls --color=auto"
alias l="ls --color=auto -lhA"
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias -- -='cd -'
alias gr='cd $(git rev-parse --show-toplevel)'
alias upall='brew upgrade --greedy;brew cleanup --prune-prefix;brew cleanup --prune=0 -s;rustup update;cargo install-update --all'

PROMPT='%F{magenta}${venv_info_0}%f%(!.%F{magenta}%n%f.%F{green}%n%f)%F{8}@%f%F{green}%m%f%F{8}:%f%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %(?.%F{white}-%f.%F{red}%? %f)%F{cyan}❯ %f'

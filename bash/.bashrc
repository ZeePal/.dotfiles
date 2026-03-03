# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

source "$HOME/bin/helpers/sh_env"

addToPath "$HOME/.npm-global/bin"
addToPathFront "$HOME/go/bin"
addToPathFront "$HOME/.cargo/bin"
addToPathFront "$HOME/.local/bin"
addToPathFront "$HOME/bin"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
export LESS=-i

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Starship
eval "$(starship init bash)"

# Eternal bash history.
shopt -s histappend
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="_pre_starship_prompt_commands;starship_precmd"
function _pre_starship_prompt_commands {
    local STATUS=$? # Passthrough the last exit code for starship
    history -a
    return $STATUS
}
export HISTCONTROL=ignoreboth
export HISTIGNORE="export AWS_ACCESS_KEY_ID=*:export AWS_SECRET_ACCESS_KEY=*:export AWS_SESSION_TOKEN=*"

# fzf
source /usr/share/doc/fzf/examples/key-bindings.bash
source /usr/share/bash-completion/completions/fzf

export GOPATH="$HOME/go"
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock" # docker rootless

complete -C '/usr/local/bin/aws_completer' aws
complete -C '/usr/local/bin/aws_completer' a

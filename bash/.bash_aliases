alias g=git
alias gs="git status"

alias gd="git diff"
alias gD="git difftool --dir-diff"
alias gdc="git diff --cached"
alias gDc="git difftool --dir-diff --cached"

alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gf="git pull --ff-only"
alias gfm="gcom && gf"
alias gfa="git pull --ff-only --all"

alias gco="git checkout"
alias gcom='git checkout "$(remote_default="$(git branch -lr origin/HEAD)";remote_default="${remote_default##*/}";echo "${remote_default:-main}")"'
alias gcon="git checkout -b"

alias o=xdg-open
alias open=xdg-open
alias rga='rg -uuu'
alias l='exa'
alias ll='exa -al'
alias la='ls -A'
alias pw='pwgen -cnys1 32 1'
alias pws='pwgen -cns1 32 1'
alias table="column -t"

function jat() { jq . "${1:--}" | bat -l json; }
alias p=parallel
alias pxargs='parallel -X --group'

complete -o nospace -F _fzf_dir_completion mcd
function mcd { mkdir -p "$1" && cd "$1"; }

alias srm='shred -f -u -v -z --random-source=<(openssl enc -aes-128-ctr -pbkdf2 -nosalt -pass "pass:$(dd if=/dev/urandom bs=128 count=1 status=none |base64 -w 0)" </dev/zero)'
alias generate_random='openssl enc -aes-128-ctr -pbkdf2 -nosalt -pass "pass:$(dd if=/dev/urandom bs=128 count=1 status=none |base64 -w 0)" </dev/zero'

alias gssh='gcloud compute ssh --tunnel-through-iap'
alias glogin='gcloud auth login --update-adc'

function mvd {
    for file in "$@"; do
        local enabled_name="${file%.DISABLED}"
        local disabled_name="${enabled_name}.DISABLED"

        if [ -e "$enabled_name" ]; then
            mv --no-clobber --verbose "$enabled_name" "$disabled_name"
        elif [ -e "$disabled_name" ]; then
            mv --no-clobber --verbose "$disabled_name" "$enabled_name"
        else
            echo "WARNING: Unable to locate '$enabled_name' or '$disabled_name'" >&2
        fi
    done
}

_simpler_cd_completer() {
    local cur prev words cword
    _init_completion || return
    local IFS='
' i j k
    compopt -o filenames
    for i in ${CDPATH//:/'
'}; do
        k="${#COMPREPLY[@]}"
        for j in $(compgen -d -- $i/$cur); do
            if [[ ! -d ${j#$i/} ]]; then
                j+="/"
            fi
            COMPREPLY[k++]=${j#$i/}
        done
    done
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        i=${COMPREPLY[0]}
        if [[ "$i" == "$cur" && $i != "*/" ]]; then
            COMPREPLY[0]="${i}/"
        fi
    fi
    return
}

function _gcd { CDPATH="$HOME/git/" _simpler_cd_completer "$@"; }
complete -o nospace -F _gcd gcd
function gcd { cd "$HOME/git/$1"; }

function _tcd { CDPATH=/tmp/phtest/ _simpler_cd_completer "$@"; }
complete -o nospace -F _tcd tcd
function tcd {
    local folder="/tmp/phtest/$1"
    [ -d "$folder" ] || mkdir -p "$folder"
    cd "$folder"
}

alias h="howdoi -c"
alias hm="h -n5"
alias hs="h --save"
alias hv="h --view"
alias hr="h --remove"

function gclone() (
    set -e
    local default_git_origin
    default_git_origin="$(<~/.config/ZeePal/default_git_origin)"
    local repo="${default_git_origin//\{REPO\}/${1:?}}"
    shift 1
    git clone "$repo" "$@"
)

function ds {
    if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
        echo "Usage: $0 DOCKER_IMAGE [SHELL_COMMAND]" >&2
        return 1
    fi
    local image="${1:?}"
    if [ "$#" -eq 1 ]; then
        docker run -it --entrypoint /bin/sh "$image" -c 'if [ -e /bin/bash ];then /bin/bash; else /bin/sh;fi'
    else
        docker run -it --entrypoint /bin/sh "$image" -c 'if [ -e /bin/bash ];then /bin/bash -c "$1"; else /bin/sh -c "$1";fi' -- "${2:?}"
    fi
}

alias t=terraform
alias trm="rm -rf .terraform/ .terraform.lock.hcl"
alias ti="terraform init"
alias tv="terraform validate"

alias tp="terraform plan -parallelism=1000 -out plan.tfplan"
alias tpa="terraform apply -parallelism=1000 plan.tfplan"
alias tpl="terraform plan -parallelism=1000 -lock=false"

alias ta="terraform apply -parallelism=1000 -auto-approve"
alias taa="terraform apply -parallelism=1000"

alias tg="terraform graph -draw-cycles|dot -Tsvg > /tmp/graph.svg && xdg-open /tmp/graph.svg"

alias a=aws

s() { # search
    : | fzf \
        --disabled \
        --bind "change:reload:sleep 0.1; \
                  command rg --line-number \
                            --column \
                            --no-heading \
                            --color=always \
                            --smart-case {q} \
                            $* \
                  || :" \
        --ansi \
        --delimiter ":" \
        --with-nth '1,2,4..' \
        --preview "command bat --style=header,grid,numbers,changes \
                           --color=always \
                           --highlight-line {2} \
                           {1}" \
        --preview-window 'up:70%,border-bottom,~3,+{2}+3/2' \
        --bind "enter:execute:vi '+call cursor({2},{3})' {1}" \
        --bind 'ctrl-y:execute-silent(echo -n {4..} | xclip -selection clipboard)+abort'
}

alias python=python3

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

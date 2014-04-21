# .bashrc

# if not running interactively, don't do anything
[ -z "$PS1" ] && return

# add local bin path
PATH="$HOME/.bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/usr/local/sbin:$PATH"
PATH="/sbin:$PATH"

export LANG="ru_RU.UTF-8"

export EDITOR=vim

# don't put duplicate lines in the history
export HISTCONTROL=ignoreboth:erasedups

# set history length
HISTFILESIZE=1000000000
HISTSIZE=1000000

# append to the history file, don't overwrite it
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry (allows easy re-editing of multi-line commands)
shopt -s cmdhist
# cd to a directory by typing its name
shopt -s autocd

# chdir from absolute path to relative
function cwd-abs-to-rel {
    reg1="^/run/media/`whoami`/\([A-Za-z_-]\+\)/home/`whoami`/"
    reg2="^/media/`whoami`/\([A-Za-z_-]\+\)/home/`whoami`/"
    reg3="^/media/\([A-Za-z_-]\+\)/home/`whoami`/"
    if echo "`pwd`" | grep "$reg1" &>/dev/null \
    || echo "`pwd`" | grep "$reg2" &>/dev/null \
    || echo "`pwd`" | grep "$reg3" &>/dev/null; then
        sed_search=
        if echo "`pwd`" | grep "$reg1" &>/dev/null; then
            sed_search="$reg1"
        elif echo "`pwd`" | grep "$reg2" &>/dev/null; then
            sed_search="$reg2"
        elif echo "`pwd`" | grep "$reg3" &>/dev/null; then
            sed_search="$reg3"
        fi
        sed_search=$(echo "$sed_search" | sed -e 's/\//\\\//g')
        mount_point_name=$(echo "`pwd`" | sed -e "s/$sed_search.*$/\1/")
        abs_tail=$(echo "`pwd`" | sed -e "s/$sed_search//")
        new_cwd="$HOME/$mount_point_name/$abs_tail/"
        if [ -d "$new_cwd" ]; then
            if [ -d "$HOME/$abs_tail/" ]; then
                cd "$HOME/$abs_tail/"
            else
                cd "$new_cwd"
            fi
        fi
        unset sed_search mount_point_name abs_tail new_cwd
    fi
    unset reg1 reg2 reg3
}
cwd-abs-to-rel

# setup color variables
color_is_on=
color_red=
color_green=
color_yellow=
color_blue=
color_white=
color_gray=
color_bg_red=
color_off=
color_user=
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_is_on=true
    color_red="\[$(/usr/bin/tput setaf 1)\]"
    color_green="\[$(/usr/bin/tput setaf 2)\]"
    color_yellow="\[$(/usr/bin/tput setaf 3)\]"
    color_blue="\[$(/usr/bin/tput setaf 6)\]"
    color_white="\[$(/usr/bin/tput setaf 7)\]"
    color_gray="\[$(/usr/bin/tput setaf 8)\]"
    color_purple="\[$(/usr/bin/tput setaf 5)\]"
    color_off="\[$(/usr/bin/tput sgr0)\]"

    color_error="$(/usr/bin/tput setab 1)$(/usr/bin/tput setaf 7)"
    color_error_off="$(/usr/bin/tput sgr0)"

    # set user color
    case `id -u` in
        0) color_user="$color_red" ;;
        *) color_user="$color_green" ;;
    esac
fi

# 256 colors in terminal
export TERM=xterm-256color

# grep colorize
export GREP_OPTIONS="--color=auto"

if [ -f ~/.hostname ]; then
    LOCAL_HOSTNAME="`cat ~/.hostname`"
else
    LOCAL_HOSTNAME="$HOSTNAME"
fi

# permission symbol
perm_symbol=
case `id -u` in
    0) perm_symbol="${color_red}#${color_off}" ;;
    *) perm_symbol="${color_green}\$${color_off}" ;;
esac

function prompt_command {
    local PWDNAME=$PWD
    local remote=false
    local PS1_REMOTE=

    # beautify working directory name
    if [[ "${HOME}" == "${PWD}" ]]; then
        PWDNAME="~"
    elif [[ "${HOME}" == "${PWD:0:${#HOME}}" ]]; then
        PWDNAME="~${PWD:${#HOME}}"
    fi

    # detect remote mount
    df -l "$PWD" &> /dev/null
    if [ $? -eq 1 ]; then
        remote=true
        PS1_REMOTE=" (remote)"
    fi

    # calculate prompt length
    local PS1_length=$((${#USER}+${#LOCAL_HOSTNAME}+${#PWDNAME}+${#PS1_REMOTE}+3))
    local FILL=

    # if length is greater, than terminal width
    if [[ $PS1_length -gt $COLUMNS ]]; then
        # strip working directory name
        PWDNAME="...${PWDNAME:$(($PS1_length-$COLUMNS+3))}"
    else
        # else calculate fillsize
        local fillsize=$(($COLUMNS-$PS1_length))
        FILL=$color_purple
        while [[ $fillsize -gt 0 ]]; do FILL="${FILL}─"; fillsize=$(($fillsize-1)); done
        FILL="${FILL}${color_off}"
    fi

    if $color_is_on; then
        if $remote; then
            PS1_REMOTE=" (${color_red}remote${color_off})"
        fi
    fi

    # set new color prompt
    PS1="${color_user}${USER}${color_off}"
    PS1="${PS1}@${color_yellow}${LOCAL_HOSTNAME}${color_off}"
    PS1="${PS1}:${color_blue}${PWDNAME}${color_off}"
    PS1="${PS1}${PS1_REMOTE}"
    PS1="${PS1} ${FILL}\n${perm_symbol} "
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command
# set new b/w prompt (will be overwritten in 'prompt_command' later for color prompt)
PS1="${color_user}\u${color_off}"
PS1="${PS1}@${color_yellow}${LOCAL_HOSTNAME}${color_off}:"
PS1="${PS1}${color_blue}\w${color_off}\n"
PS1="${PS1}${perm_symbol} "

# Postgres won't work without this
export PGHOST=/tmp

# this is for delete words by ^W
tty -s && stty werase ^- 2>/dev/null

# aliases
if [ "`uname`" != 'FreeBSD' ]; then
    alias ls='ls --color=auto'
    eval "`dircolors`"
fi
alias la='ls -lah'
alias al='ls -lah'
alias l='ls -lah'
alias gits='git status'
alias gitl='git log'
alias gitc='git commit'
alias gitcm='git commit -m'
alias gitcam='git commit -am'
alias gita='git add'
alias gitd='git diff'

set -o vi

# incremental history search in vi mode by jk
bind -m vi '"k": history-search-backward'
bind -m vi '"j": history-search-forward'

# deleting in Insert mode ^H (backward) and ^L (forward)
bind -m vi-insert '"\C-l": delete-char'

function update-git-configs {
    local CONFIGS_DIR="$HOME/.gitconfigs"
    local OLDPATH="$PWD"
    local list=
    local path=
    local action=pull

    local USAGE="
USAGE
=====

-h, --help
	Show this message

-u, --upload
	git push
"

    for i in "$@"; do
        case $i in
            -h|--help)
                echo "$USAGE"
                return 0
                ;;
            -u|--upload)
                action=push
                ;;
            *)
                echo "Unknown argument \"$i\"" 1>&2
                echo "$USAGE"
                return 1
                ;;
        esac
    done

    if [[ ! -d "$CONFIGS_DIR" ]]; then
        echo "Git-configs directory \"$CONFIGS_DIR\" is not exist" 1>&2
        return 1
    fi

    list=$(ls -A "${CONFIGS_DIR}")
    if [[ $? -ne 0 ]]; then
        echo "List directory \"$CONFIGS_DIR\" error" 1>&2
        return 1
    fi

    for line in $list; do
        path="$CONFIGS_DIR/$line"
        if [[ ! -d "$path" ]]; then continue; fi # if list item is not a directory
        cd "$path"

        if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
            echo "Git repo \"$line\" have something to commit (skipped $action)" 1>&2
            continue
        fi
        
        echo "Git $action for \"$line\" repo"
        git $action
    done

    cd "$OLDPATH"
}

# vim: set ts=4 sw=4 expandtab :

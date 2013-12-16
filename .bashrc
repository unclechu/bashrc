# .bashrc

# if not running interactively, don't do anything
[ -z "$PS1" ] && return

# add local bin path
PATH="$HOME/.bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/usr/local/sbin:$PATH"

export LANG="ru_RU.UTF-8"

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

# some kind of optimization - check if git installed only on config load
PS1_GIT_BIN=$(which git 2>/dev/null)

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
    local PS1_GIT=
    local GIT_BRANCH=
    local GIT_DIRTY=
    local PWDNAME=$PWD
    local REMOTE=false
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
        REMOTE=true
        PS1_REMOTE=" (${color_red}remote${color_off})"
    fi

    # parse git status and get git variables
    if [[ ! -z $PS1_GIT_BIN ]] && ! $REMOTE; then
        # check we are in git repo
        local CUR_DIR=$PWD
        while [[ ! -d "${CUR_DIR}/.git" ]] && [[ ! "${CUR_DIR}" == "/" ]] && [[ ! "${CUR_DIR}" == "~" ]] && [[ ! "${CUR_DIR}" == "" ]]; do CUR_DIR=${CUR_DIR%/*}; done
        if [[ -d "${CUR_DIR}/.git" ]]; then
            # 'git repo for dotfiles' fix: show git status only in home dir and other git repos
            if [[ "${CUR_DIR}" != "${HOME}" ]] || [[ "${PWD}" == "${HOME}" ]]; then
                # get git branch
                GIT_BRANCH=$($PS1_GIT_BIN symbolic-ref HEAD 2>/dev/null)
                if [[ ! -z $GIT_BRANCH ]]; then
                    GIT_BRANCH=${GIT_BRANCH#refs/heads/}

                    # get git status
                    local GIT_STATUS=$($PS1_GIT_BIN status --porcelain 2>/dev/null)
                    [[ -n $GIT_STATUS ]] && GIT_DIRTY=1
                fi
            fi
        fi
    fi

    # build b/w prompt for git
    [[ ! -z $GIT_BRANCH ]] && PS1_GIT=" (git: ${GIT_BRANCH})"

    # calculate prompt length
    local PS1_length=$((${#USER}+${#LOCAL_HOSTNAME}+${#PWDNAME}+${#PS1_GIT}+${#PS1_REMOTE}+3))
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
        # build git status for prompt
        if [[ ! -z $GIT_BRANCH ]]; then
            if [[ -z $GIT_DIRTY ]]; then
                PS1_GIT=" (git: ${color_green}${GIT_BRANCH}${color_off})"
            else
                PS1_GIT=" (git: ${color_red}${GIT_BRANCH}${color_off})"
            fi
        fi
    fi

    # set new color prompt
    PS1="${color_user}${USER}${color_off}"
    PS1="${PS1}@${color_yellow}${LOCAL_HOSTNAME}${color_off}"
    PS1="${PS1}:${color_blue}${PWDNAME}${color_off}"
    PS1="${PS1}${PS1_GIT}"
    PS1="${PS1}${PS1_REMOTE}"
    PS1="${PS1} ${FILL}\n${perm_symbol} "

    # get cursor position and add new line if we're not in first column
    echo -en "\033[6n" && read -sdR CURPOS
    [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}↵${color_error_off}"

    # set title
    echo -ne "\033]0;${USER}@${LOCAL_HOSTNAME}:${PWDNAME}"; echo -ne "\007"
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
alias ls='ls --color=auto'
eval "`dircolors`"
alias la='ls -la'
alias al='ls -la'

# vi-mode
set -o vi
bind -m vi-insert '"\e[1;5C": vi-forward-word'
bind -m vi-insert '"\e[1;5D": vi-backward-word'
bind -m vi '"\e[1;5C": vi-forward-word'
bind -m vi '"\e[1;5D": vi-backward-word'
bind -m vi-insert '"\C-n": menu-complete'
bind -m vi-insert '"\C-p": menu-complete-backward'

# incremental history search by arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# vim: set ts=4 sw=4 expandtab :

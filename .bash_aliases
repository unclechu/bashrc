#!/usr/bin/env bash
# .bash_aliases

shopt -s expand_aliases

# `ls` stuff
if [[ `uname` != FreeBSD ]]; then
	alias ls='ls --color=auto'
	eval "`dircolors`"
else
	alias ls='ls -G'
fi
alias la='ls -lah'
alias al='ls -lah'
alias  l='ls -lah'

# git stuff
alias gits='git status'
alias gitl='git log'
alias gitc='git commit'
alias gitcm='git commit -m'
alias gita='git add'
alias gitd='git diff'
alias gitds='git diff --staged'
alias gitb='git branch | grep ^* | awk "{print \$2}"'
alias gitbn='git branch'
alias gitco='git checkout'
alias gitpl='git pull origin `gitb`'
alias gitph='git push origin `gitb`'

# to generate tmux session socket file path based on username
alias tmuxs=$'printf \'/tmp/%s-tmux-%s\' "`whoami`" '

# tmux shortcuts
alias tm=tmux
alias tmsh=tmuxsh
alias tma='tm a 2>/dev/null || tm new -s main'

# shred with my favorite options
alias shreddy='shred -vufz -n10'

# shortcut for gpaste cli
alias gp=$(
	if   [[ -x `which gpaste-client 2>/dev/null` ]]; then echo 'gpaste-client'
	elif [[ -x `which gpaste        2>/dev/null` ]]; then echo 'gpaste'
	else echo 'echo gpaste not found >&2 ; false'
	fi
)

# any available vi-like editor
alias v=$(
	if   [[ -n $EDITOR ]]; then printf '%s' "$EDITOR"
	elif [[ -x `which nvim 2>/dev/null` ]]; then echo nvim
	elif [[ -x `which  vim 2>/dev/null` ]]; then echo  vim
	elif [[ -x `which  vi  2>/dev/null` ]]; then echo  vi
	else echo 'echo not found any implementation of vi >&2 ; false'
	fi
)

# HASKell Interactive (ghci from default stackage LTS)
alias haski='stack exec ghci --'

# go "$1" levels up
.x() {
	local c=
	if (( $# != 1 )); then
		>&2 printf 'Incorrect arguments count (must be 1, got %d)!\n' "$#"
		return 1
	elif ! [[ $1 =~ ^[0-9]+$ ]]; then
		>&2 printf 'Incorrect go up level argument '
		>&2 printf '(must be an integer, got "%s")!\n' "$1"
		return 1
	else
		c=$1; shift || return
	fi
	local command; command='cd '
	for i in $(seq -- "$c"); do
		command=${command}../
	done
	$command
	return $?
}

# silent process in background
burp() {
	if (( $# < 1 )); then
		>&2 echo 'Not enough arguments to "burp"!'
		return 1
	fi
	local APP; APP=$1; shift || return
	"$APP" "$@" 0</dev/null &>/dev/null &
	return $?
}

# prints last command as string
lastc() {
	local last; last=$(history 2 | sed -e '$d') || return
	perl -e '$_ = shift; chomp; s/^[ 0-9]+[ ]+//; print' -- "$last" || return
}

# 'mkdir' and 'cd' to it
mkdircd() {
	mkdir "$@" || return
	local dir=
	for arg in "$@"; do
		if [[ ${arg:0:1} != '-' ]]; then dir=$arg; fi
	done
	if [[ -n $dir && -d $dir ]]; then
		cd -- "$dir" || return
	fi
}

# helper to remove TMUX variable from running application (support aliases)
notm() {
	if (( $# == 0 )); then
		>&2 echo 'No app specified to run!'
		return 1
	fi
	local APP; APP=$1; shift || return
	local ALIASED; ALIASED=${BASH_ALIASES[$APP]}
	export TMUX=
	if [[ -n $ALIASED ]]; then
		bash -c $". ~/.bash_aliases && $ALIASED \"\$@\"" -- "$@"
	else
		"$APP" "$@"
	fi
	return $?
}

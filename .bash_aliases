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

# shortcut for gpaste cli
alias gp=$(
	([[ -x `which gpaste-client 2>/dev/null` ]] && echo 'gpaste-client' ||
	([[ -x `which gpaste        2>/dev/null` ]] && echo 'gpaste'        ||
		echo 'echo gpaste not found >&2 ; false'))
)

# any available vi-like editor
alias v=$(
	([[ -n $EDITOR ]] && printf '%s' "$EDITOR"      ||
	([[ -x `which nvim 2>/dev/null` ]] && echo nvim ||
	([[ -x `which  vim 2>/dev/null` ]] && echo  vim ||
	([[ -x `which  vi  2>/dev/null` ]] && echo  vi  ||
		echo 'echo not found any implementation of vi >&2 ; false'))))
)

# HASKell Interactive (ghci from default stackage LTS)
alias haski='stack exec ghci --'

# go "$1" levels up
.x() {
	local c=
	if (( $# != 1 )); then
		echo 'incorrect arguments count' >&2
		return 1
	elif [[ $1 != $[$1] ]]; then
		echo 'incorrect go up level argument' >&2
		return 1
	else
		c=$1
	fi
	local command='cd '
	for i in $(seq -- "$c"); do
		command="${command}../"
	done
	$command
	return $?
}

# silent process in background
burp() {
	if (( $# < 1 )); then
		echo 'not enough arguments to burp' >&2
		return 1
	fi
	local app=$1
	shift
	"$app" "$@" 0</dev/null &>/dev/null &
	return $?
}

# prints last command as string
lastc() {
	local last=$(history 2 | sed -e '$d')
	perl -e '$_ = shift; chomp; s/^[ 0-9]+[ ]+//; print' -- "$last"
	return $?
}

# 'mkdir' and 'cd' to it
mkdircd() {
	mkdir "$@" || return $?
	local dir=
	for arg in "$@"; do
		[[ ${arg:0:1} != '-' ]] && dir=$arg
	done
	if [[ -n $dir && -d $dir ]]; then
		cd -- "$dir"
		return $?
	fi
}

# helper to remove TMUX variable from running application (support aliases)
notm() {
	(( $# == 0 )) && { echo 'no app specified to run' >&2; return 1; }
	local app=$1; shift
	local aliased=${BASH_ALIASES[$app]}
	export TMUX=
	if [[ -n $aliased ]]; then
		bash -c $". ~/.bash_aliases && $aliased \"\$@\"" -- "$@"
	else
		"$app" "$@"
	fi
	return $?
}

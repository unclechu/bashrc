#!/usr/bin/env bash
# .bash_aliases

shopt -s expand_aliases

# ls stuff
if [[ `uname` != FreeBSD ]]; then
	alias ls='ls --color=auto'
	eval "`dircolors`"
else
	alias ls='ls -G'
fi
alias la='ls -lah'
alias al='ls -lah'
alias l='ls -lah'

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

alias tmuxs=$'printf \'/tmp/%s-tmux-%s\' "`whoami`" '

# shortcut for gpaste cli
alias gp=$(
	[[ -x `which gpaste-client 2>/dev/null` ]] && echo 'gpaste-client' || \
	([[ -x `which gpaste 2>/dev/null` ]] && echo 'gpaste' || \
		echo 'echo gpaste not found 1>&2')
)

# go "$1" levels up
.x() {
	local c=
	if (( $# != 1 )); then
		echo 'incorrect arguments count' 1>&2
		return 1
	elif [[ $1 != $[$1] ]]; then
		echo 'incorrect go up level argument' 1>&2
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
		echo 'not enough arguments to burp' 1>&2
		return 1
	fi
	local app=$1
	shift
	"$app" "$@" 0</dev/null 1>/dev/null 2>/dev/null &
	return $?
}

# prints last command as string
last-cmd() {
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

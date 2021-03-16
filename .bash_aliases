#! /usr/bin/env bash
# .bash_aliases

shopt -s expand_aliases

# "ls" stuff
if [[ $(uname) != FreeBSD ]]; then
	alias ls='ls --color=auto'
	eval "$(dircolors)"
else
	alias ls='ls -G'
fi
alias la='ls -lah'
alias al='ls -lah'
alias  l='ls -lah'
alias  L='ls -lAh'

# git stuff
alias gits='git status'
alias gitl='git log'
alias gitl1='git log -1'
alias gitl2='git log -2'
alias gitl3='git log -3'
alias gitl4='git log -4'
alias gitl5='git log -5'
alias gitls='git log --show-signature'
alias gitls1='git log --show-signature -1'
alias gitls2='git log --show-signature -2'
alias gitls3='git log --show-signature -3'
alias gitls4='git log --show-signature -4'
alias gitls5='git log --show-signature -5'
alias gitc='git commit'
alias gitca='git commit --amend'
alias gitcs='git commit -S'
alias gitcsa='git commit -S --amend'
alias gitcas='git commit --amend -S'
alias gitcm='git commit -m'
alias gitcam='git commit --amend -m'
alias gitcsm='git commit -S -m'
alias gitcsam='git commit -S --amend -m'
alias gitcasm='git commit --amend -S -m'
alias gita='git add'
alias gitd='git diff'
alias gitds='git diff --staged'
alias gitb='git branch | grep ^* | cut -d " " -f 2'
alias gitbn='git branch'
alias gitco='git checkout'
alias gitpl='git pull origin -- "$(gitb)"'
alias gitph='git push origin -- "$(gitb)"'

# to generate tmux session socket file path based on username
alias tmuxs=$'printf \'/tmp/%s-tmux-%s\' "$(whoami)" '

# tmux shortcuts
alias tm=tmux
alias tmsh=tmuxsh
alias tma='tm a 2>/dev/null || tm new -s main'

# shred with my favorite options
alias shreddy='shred -vufz -n10'

# nix-shell with forwarded $SHELL
alias nsh=$(
	echo -n "nix-shell --command '"
	echo -n $'export SHELL=\'"\'${SHELL//\\\'}\'"\' && "$SHELL"'
	echo -n "'"
)

# shortcut for gpaste cli
alias gp=$(
	if   [[ -x $(type -fp gpaste-client 2>/dev/null) ]]; then echo 'gpaste-client'
	elif [[ -x $(type -fp gpaste        2>/dev/null) ]]; then echo 'gpaste'
	else echo 'echo gpaste not found >&2 ; false'
	fi
)

# Copy to system clipboard without any line breaks (“i” for “inline”).
alias gpi='perl -pe chomp | gp'

# any available vi-like editor
alias v=$(
	if   [[ -n $EDITOR ]]; then printf %s "$EDITOR"
	elif [[ -x $(type -fp nvim 2>/dev/null) ]]; then echo nvim
	elif [[ -x $(type -fp  vim 2>/dev/null) ]]; then echo  vim
	elif [[ -x $(type -fp  vi  2>/dev/null) ]]; then echo  vi
	else echo 'echo not found any implementation of vi >&2 ; false'
	fi
)

# HASKell Interactive (ghci from default stackage LTS)
alias haski='stack exec ghci --'

# go "$1" levels up
.x() {
	local c
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
	local cmd; cmd='cd '
	for _ in $(seq -- "$c"); do
		cmd=${cmd}../
	done
	$cmd
	return
}

# silent process in background
burp() {
	if (( $# < 1 )); then
		>&2 echo 'Not enough arguments for "burp"!'
		return 1
	fi
	local APP; APP=$1; shift || return
	"$APP" "$@" 0</dev/null &>/dev/null &
	return
}

# prints last command as string
lastc() {
	local last; last=$(history 2 | sed -e '$d') || return
	perl -e '$_ = shift; chomp; s/^[ 0-9]+[ ]+//; print' -- "$last" || return
}

# 'mkdir' and 'cd' to it
mkdircd() {
	mkdir "$@" || return
	local dir arg
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
	# This subshell wrap is needed to encapsulate the removal of ‘TMUX’
	(
	unset TMUX TMUX_TMPDIR TMUX_PANE
	export -n TMUX TMUX_TMPDIR TMUX_PANE
	if [[ -n $ALIASED ]]; then
		local aliases_file
		if [[ -n $BASH_DIR_PLACEHOLDER ]]; then
			aliases_file=$BASH_DIR_PLACEHOLDER/.bash_aliases
		else
			aliases_file=~/.bash_aliases
		fi
		"$SHELL" -c $". $aliases_file && $ALIASED \"\$@\"" -- "$@"
	else
		"$APP" "$@"
	fi
	)
	return
}

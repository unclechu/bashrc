#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
f() (
	set -Eeuo pipefail || exit
	if [[ ! -v NO_TMUX_F || -z $NO_TMUX_F ]] \
	&& [[ -v TMUX && -n $TMUX ]]; then
		fzf-tmux "$@"
	else
		fzf "$@"
	fi
)

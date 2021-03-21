#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
f() (
	set -Eeuo pipefail || exit
	if [[ -v TMUX ]] && [[ -n $TMUX ]]; then sk-tmux "$@"; else sk "$@"; fi
)

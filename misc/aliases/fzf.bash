#! /usr/bin/env bash

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
f() (
	set -Eeuo pipefail || exit
	if [[ -v TMUX ]] && [[ -n $TMUX ]]; then fzf-tmux "$@"; else fzf "$@"; fi
)

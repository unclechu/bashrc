#! /usr/bin/env bash

f() {
	# Encapsulate `set` (otherwise cancellation closes the shell)
	(
	set -eu
	if [[ -v TMUX ]] && [[ -n $TMUX ]]; then fzf-tmux "$@"; else fzf "$@"; fi
	)
}

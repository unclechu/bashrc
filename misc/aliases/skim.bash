#! /usr/bin/env bash

f() {
	# Encapsulate `set` (otherwise cancellation closes the shell)
	(
	set -eu || exit
	if [[ -v TMUX ]] && [[ -n $TMUX ]]; then sk-tmux "$@"; else sk "$@"; fi
	)
}

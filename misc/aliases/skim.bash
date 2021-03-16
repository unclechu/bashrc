#! /usr/bin/env bash

f() {
	# Encapsulate `set` (otherwise cancellation closes the shell)
	(
	set -eu
	if [[ -n $TMUX ]]; then sk-tmux "$@"; else sk "$@"; fi
	)
}

#! /usr/bin/env bash

f() {
	set -eu
	if [[ -n $TMUX ]]; then fzf-tmux "$@"; else fzf "$@"; fi
}

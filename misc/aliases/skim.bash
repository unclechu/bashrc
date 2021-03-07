#! /usr/bin/env bash

f() {
	set -eu
	if [[ -n $TMUX ]]; then sk-tmux "$@"; else sk "$@"; fi
}

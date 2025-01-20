#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
f() (
	set -Eeuo pipefail || exit

	local in_tmux=false colors_arg
	colors_arg=()
	if [[ -v TMUX && -n $TMUX ]]; then
		in_tmux=true
		if &>/dev/null type tmuxsh; then
			local out
			out=$(tmuxsh co s)
			colors_arg=("--color=$out")
		fi
	fi

	if [[ ! -v NO_TMUX_F || -z $NO_TMUX_F ]] && "$in_tmux"; then
		fzf-tmux "${colors_arg[@]}" "$@"
	else
		fzf "${colors_arg[@]}" "$@"
	fi
)

# (h)istory + (f)uzzy
if [[ ! -v NO_TMUX_F || -z $NO_TMUX_F ]] && [[ -v TMUX && -n $TMUX ]]; then
	alias hf='history | fzf-tmux --tac --no-sort | sed "s/^\s*[0-9]\+\s\+//"'
else
	alias hf='history | fzf --tac --no-sort | sed "s/^\s*[0-9]\+\s\+//"'
fi

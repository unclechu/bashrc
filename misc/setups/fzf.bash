#! /usr/bin/env bash
# This module is supposed to be combined with "fuzzy-finder.bash"

if [[ -f $HOME/.fzf.bash ]]; then
	. "$HOME/.fzf.bash"
else
	. /usr/share/fzf/shell/key-bindings.bash
fi

bind '"\ec": nop'

#!/bin/bash

if [[ -n $TMUX ]]; then
	__tmux_cd=$(tmux showenv _TMUX_CD 2>/dev/null)
	if (( $? == 0 )) && [[ -n $__tmux_cd ]]; then
		__tmux_cd=$(printf '%s' "$__tmux_cd" | perl -pe 's/^_TMUX_CD=//' 2>/dev/null)
		if (( $? == 0 )) && [[ -n $__tmux_cd ]] && [[ -d $__tmux_cd ]]; then
			cd -- "$__tmux_cd"
		fi
	fi
	unset __tmux_cd
fi

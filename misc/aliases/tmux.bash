#! /usr/bin/env bash

# to generate tmux session socket file path based on username
alias tmuxs=$'printf \'/tmp/%s-tmux-%s\' "$(whoami)" '

# tmux shortcuts
alias tm=tmux
alias tmsh=tmuxsh
alias tma='tm a 2>/dev/null || tm new -s main'

# helper to remove TMUX variable from running application (support aliases)
notm() {
	if (( $# == 0 )); then
		>&2 echo 'No app specified to run!'
		return 1
	fi
	local APP; APP=$1; shift || return
	local ALIASED; ALIASED=${BASH_ALIASES[$APP]}
	# This subshell wrap is needed to encapsulate the removal of ‘TMUX’
	(
	unset TMUX TMUX_TMPDIR TMUX_PANE
	export -n TMUX TMUX_TMPDIR TMUX_PANE
	if [[ -n $ALIASED ]]; then
		local aliases_file
		if [[ -n $BASH_DIR_PLACEHOLDER ]]; then
			aliases_file=$BASH_DIR_PLACEHOLDER/.bash_aliases
		else
			aliases_file=~/.bash_aliases
		fi
		"$SHELL" -c $". $aliases_file && $ALIASED \"\$@\"" -- "$@"
	else
		"$APP" "$@"
	fi
	)
	return
}

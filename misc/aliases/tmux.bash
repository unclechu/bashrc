#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# to generate tmux session socket file path based on username
alias tmuxs=$'printf \'/tmp/%s-tmux-%s\' "$(whoami)" '

# tmux shortcuts
alias tm=tmux
alias tmsh=tmuxsh
alias tma='tm a 2>/dev/null || tm new -s main'

# helper to remove TMUX variable from running application (support aliases)
notm() (
	set -Eeuo pipefail || exit

	if (( $# == 0 )); then
		>&2 echo No app specified to run!
		return 1
	fi

	local APP=$1; shift
	unset TMUX TMUX_TMPDIR TMUX_PANE
	export -n TMUX TMUX_TMPDIR TMUX_PANE

	if [[ -v "BASH_ALIASES[$APP]" ]]; then
		local aliases_file=
		if [[ -v BASH_DIR_PLACEHOLDER ]] && [[ -n $BASH_DIR_PLACEHOLDER ]]; then
			aliases_file='. $BASH_DIR_PLACEHOLDER/.bash_aliases && '
		elif [[ -f ~/.bash_aliases ]]; then
			aliases_file='. ~/.bash_aliases && '
		fi
		"$SHELL" -c $"${aliases_file}${BASH_ALIASES[$APP]} \"\$@\"" -- "$@"
	else
		"$APP" "$@"
	fi
)

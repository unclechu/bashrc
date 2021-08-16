#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# This module works both for "skim" and "fzf" (it relies only on "f" function)

alias fd=$'cd -- "$(
	find . \
		\( -type d -name .cache -prune \) \
		-o \( -type d ! -path . -printf \'%P\\n\' \) \
	| f
)" && echo'

# Can’t use `notm fd` because `notm` would encapsulate the `cd`.
# This is useful when tmux ‘synchronize-panes’ feature is on and you need to
# change directory using `fd`. By default it would create new tmux pane with
# fuzzy search app started there for each pane on current window. This is here
# the synchronization breaks. `fd-notm` would use regular fuzzy search app
# (instead of tmux-specific version) that would stay in the same pane.
alias fd-notm=$'cd -- "$(
	find . \
		\( -type d -name .cache -prune \) \
		-o \( -type d ! -path . -printf \'%P\\n\' \) \
	| NO_TMUX_F=1 f
)" && echo'

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
vf() (
	set -Eeuo pipefail || exit

	# Guard dependencies
	>/dev/null type f
	>/dev/null type v

	local file exit_code

	if (( $# == 1 )) && [[ $1 == notm ]]; then
		file=$(NO_TMUX_F=1 f)
		exit_code=$?
	elif (( $# == 0 )); then
		file=$(f)
		exit_code=$?
	else
		>&2 printf 'Incorrect arguments for “%s”!\n' "${FUNCNAME[0]}"
		>&2 printf 'Usage: %s [notm]\n' "${FUNCNAME[0]}"
		return 1
	fi

	if (( exit_code == 0 )) && [[ -n $file ]]; then
		v -- "$file"
	else
		return $(( exit_code ))
	fi
)

alias vf-notm='vf notm'

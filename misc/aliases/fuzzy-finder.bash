#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# This module works both for "skim" and "fzf" (it relies only on "f" function)

alias fd=$'cd -- "$(find . ! -path . -type d -printf \'%P\\n\' | f)" && echo'

# Subshell encapsulates `set` (otherwise cancellation closes the shell)
vf() (
	set -Eeuo pipefail || exit

	# Guard dependencies
	>/dev/null type f
	>/dev/null type v

	if (( $# != 0 )); then
		>&2 printf '"%s" does not accept any arguments!\n' "${FUNCNAME[0]}"
		return 1
	fi

	local FILE; FILE=$(f)
	local RETVAL=$?
	if (( RETVAL == 0 )) && [[ -n $FILE ]]; then
		v -- "$FILE"
	else
		return $(( RETVAL ))
	fi
)

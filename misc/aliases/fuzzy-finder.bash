#! /usr/bin/env bash
# This module works both for "skim" and "fzf" (it relies only on "f" function)

alias fd=$'cd -- "$(find . ! -path . -type d -printf \'%P\\n\' | f)" && echo'

vf() {
	# Encapsulate `set` (otherwise cancellation closes the shell)
	(
	if (( $# != 0 )); then
		>&2 printf '"%s" does not accept any arguments!\n' "${FUNCNAME[0]}"
		return 1
	fi

	set -eu || exit

	# Guard dependencies
	>/dev/null type f
	>/dev/null type v

	local FILE; FILE=$(f)
	local RETVAL=$?
	if (( RETVAL == 0 )) && [[ -n $FILE ]]; then
		v -- "$FILE"
	else
		return $(( RETVAL ))
	fi
	)
}

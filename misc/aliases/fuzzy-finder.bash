#! /usr/bin/env bash
# This module works both for "skim" and "fzf" (it relies only on "f" function)

alias fd=$'cd -- "$(find . ! -path . -type d -printf \'%P\\n\' | f)" && echo'

vf() {
	set -eu
	local FILE; FILE=$(f)
	local RETVAL=$?
	if (( RETVAL == 0 )) && [[ -n $FILE ]]; then
		v -- "$FILE"
	else
		return $(( RETVAL ))
	fi
}

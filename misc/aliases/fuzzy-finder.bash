# This module works both for "skim" and "fzf" (it relies only on "f" function)

alias fd=$'cd -- "`find . ! -path . -type d -printf \'%P\\n\' | f`" && echo'

vf() {
	local FILE; FILE=`f`
	local RETVAL; RETVAL=$?
	if (( $RETVAL == 0 )) && [[ -n $FILE ]]; then
		v -- "$FILE" || return
	else
		return -- "$(( $RETVAL ))"
	fi
}

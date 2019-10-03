f() {
	if [[ -n $TMUX ]]; then fzf-tmux "$@"; else fzf "$@"; fi || return -- "$?"
}

alias fd=$'cd -- "`find . ! -path . -type d -printf \'%P\\n\' | f`" && echo'

vf() {
	local FILE=`f`
	local RETVAL=$?
	if (( $RETVAL == 0 )) && [[ -n $FILE ]]; then
		v -- "$FILE" || return -- "$?"
	else
		return -- "$(( $RETVAL ))"
	fi
}

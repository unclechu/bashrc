f() {
	if [[ -n $TMUX ]]; then sk-tmux "$@"; else sk "$@"; fi || return
}

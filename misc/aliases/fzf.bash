f() {
	if [[ -n $TMUX ]]; then fzf-tmux "$@"; else fzf "$@"; fi || return
}

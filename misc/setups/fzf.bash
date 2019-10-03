export FZF_DEFAULT_COMMAND='
	find . \
		\( -depth -path "*/\.git/*" -a -not -path "*/\.git/info/*" \) -prune \
		-o -path "*/\.stack-work/*" -prune \
		-o -path "*/\.cabal/*" -prune \
		-o -path "*/node_modules/*" -prune \
		-o -path "*/bower_components/*" -prune \
		-o -type f -print \
		-o -type l -print \
		| sed s/^..//
'
. /usr/share/fzf/shell/key-bindings.bash
bind '"\ec": nop'

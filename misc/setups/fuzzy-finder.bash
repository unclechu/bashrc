# This module is supposed to be combined with either "skim.bash" or "fzf.bash"

__FUZZY_FINDER_DEFAULT_COMMAND='
	find . \
		-depth \
		\( -path "*/\.git/*" -a -not -path "*/\.git/info/*" \) -prune \
		-o -path "*/\.stack-work/*" -prune \
		-o -path "*/\.cabal/*" -prune \
		-o -path "*/node_modules/*" -prune \
		-o -path "*/bower_components/*" -prune \
		-o -type f -print \
		-o -type l -print \
		| sed s/^..//
'

export SKIM_DEFAULT_COMMAND=$__FUZZY_FINDER_DEFAULT_COMMAND
export FZF_DEFAULT_COMMAND=$__FUZZY_FINDER_DEFAULT_COMMAND

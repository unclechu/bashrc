# .bash_aliases

shopt -s expand_aliases

function ... {
	if [ $# -eq 0 ]; then
		echo 'go up level argument is required' 1>&2
		return 1
	elif [ $# -ne 1 ]; then
		echo 'incorrect arguments count' 1>&2
		return 1
	elif [ "$1" != "$[$1]" ]; then
		echo 'incorrect go up level argument' 1>&2
		return 1
	fi
	local command='cd '
	for i in $(seq $[$1]); do
		command="${command}../"
	done
	$command
	return $?
}

burp () {
	if [ $# -lt 1 ]; then
		echo 'not enough arguments to burp' 1>&2
		return 1
	fi
	local app=$1
	shift
	"$app" "$@" 0</dev/null 1>/dev/null 2>/dev/null &
	return $?
}

if [ "`uname`" != 'FreeBSD' ]; then
	alias ls='ls --color=auto'
	eval "`dircolors`"
else
	alias ls='ls -G'
fi
alias la='ls -lah'
alias al='ls -lah'
alias l='ls -lah'
alias gits='git status'
alias gitl='git log'
alias gitc='git commit'
alias gitcm='git commit -m'
alias gita='git add'
alias gitd='git diff'
alias gitds='git diff --staged'
alias gitb='git branch | grep ^* | awk "{print \$2}"'
alias gitbn='git branch'
alias gitco='git checkout'
alias gitpl='git pull origin `gitb`'
alias gitph='git push origin `gitb`'

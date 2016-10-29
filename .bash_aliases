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

clean-vim() {
	if [ $# -ne 1 ]; then
		echo 'incorrect arguments count' 1>&2
		echo 'target argument is required' 1>&2
		return 1
	fi
	local target=$1
	case "$target" in
		swap)
			find ~/.vim_swap/ -type f -name '*.swp' -exec rm {} \;
			;;
		backup)
			find ~/.vim_backup/ -type f -name '*~' -exec rm {} \;
			;;
		all)
			find ~/.vim_swap/ -type f -name '*.swp' -exec rm {} \;
			find ~/.vim_backup/ -type f -name '*~' -exec rm {} \;
			;;
		*)
			echo "unknown target argument: '$target'" 1>&2
			return 1
			;;
	esac
}

alias gp=$( \
	[ -x "`which gpaste-client 2>/dev/null`" ] && echo 'gpaste-client' || \
	([ -x "`which gpaste 2>/dev/null`" ] && echo 'gpaste' || \
	echo 'echo gpaste not found 1>&2') \
)

last-cmd() {
	local hist=$(history 2 | sed -e '$d')
	local i=$[0]
	local c=$(echo "$hist" | wc -l)
	echo "$hist" | while read line; do
		i=$[i+1]
		if [ "$i" -eq 1 ]; then
			line=$(echo "$line" | sed -e 's/^[ 0-9]\+[ ]\+//')
		fi
		if [ "$i" -eq "$c" ]; then
			echo -n "$line"
		else
			echo "$line"
		fi
	done
}

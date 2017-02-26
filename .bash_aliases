#!/bin/bash
# .bash_aliases

shopt -s expand_aliases

# ls stuff
if [[ `uname` != FreeBSD ]]; then
	alias ls='ls --color=auto'
	eval "`dircolors`"
else
	alias ls='ls -G'
fi
alias la='ls -lah'
alias al='ls -lah'
alias l='ls -lah'

# git stuff
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

# specific colorscheme for tmux
alias tmuxdc='env _TMUX_COLOR=dark  tmux'
alias tmuxlc='env _TMUX_COLOR=light tmux'

# shortcut for gpaste cli
alias gp=$(
	[[ -x `which gpaste-client 2>/dev/null` ]] && echo 'gpaste-client' || \
	([[ -x `which gpaste 2>/dev/null` ]] && echo 'gpaste' || \
		echo 'echo gpaste not found 1>&2')
)

# go "$1" levels up
function ... {
	local c=2
	if (( $# == 0 )); then
		: # it's okay, taking `...` as `... 2` (because `..` is `... 1`)
	elif (( $# != 1 )); then
		echo 'incorrect arguments count' 1>&2
		return 1
	elif [[ $1 != $[$1] ]]; then
		echo 'incorrect go up level argument' 1>&2
		return 1
	else
		c=$1
	fi
	local command='cd '
	for i in $(seq -- "$c"); do
		command="${command}../"
	done
	$command
	return $?
}

# silent process in background
function burp {
	if (( $# < 1 )); then
		echo 'not enough arguments to burp' 1>&2
		return 1
	fi
	local app=$1
	shift
	"$app" "$@" 0</dev/null 1>/dev/null 2>/dev/null &
	return $?
}

function clean-vim {
	local program=$(
cat << 'PERL'
		use v5.10; use strict; use warnings; use autodie qw(:all);
		use Env qw(HOME);
		use List::Util qw(first);
		use constant TARGET     => $ARGV[0];
		use constant ARGC       => scalar(@ARGV);
		use constant SWAP_DIR   => "$HOME/.vim_swap/";
		use constant BACKUP_DIR => "$HOME/.vim_backup/";

		sub get_help {'usage: clean-vim (swap|backup|all)'}

		if (ARGC != 1) {
			say STDERR 'incorrect arguments count: ', ARGC;
			say STDERR 'target argument is required' if ARGC == 0;
			say STDERR 'it should be only one argument' if ARGC > 1;
			say STDERR get_help();
			exit 1;
		} elsif (TARGET eq 'help') {
			say get_help();
			exit 0;
		} elsif (! defined(first {TARGET eq $_} qw(all swap backup))) {
			say STDERR qq/unknown target argument: '@{[TARGET]}'/;
			say STDERR get_help();
			exit 1;
		}

		if ((TARGET eq 'all' || TARGET eq 'swap') && -d SWAP_DIR) {
			my @files = glob SWAP_DIR . '/{,.}*.{swp,swo}';
			foreach (@files) {unlink $_}
		}

		if ((TARGET eq 'all' || TARGET eq 'backup') && -d BACKUP_DIR) {
			my @files = glob BACKUP_DIR . '/{,.}*~';
			foreach (@files) {unlink $_}
		}
PERL
	)
	perl -e "$program" -- "$@"
	return $?
}

# prints last command as string
function last-cmd {
	local last=$(history 2 | sed -e '$d')
	perl -e '$_ = shift; chomp; s/^[ 0-9]+[ ]+//; print' -- "$last"
	return $?
}

# 'mkdir' and 'cd' to it
function mkdircd {
	mkdir "$@" || return $?
	local dir=
	for arg in "$@"; do
		[[ ${arg:0:1} != '-' ]] && dir=$arg
	done
	if [[ -n $dir && -d $dir ]]; then
		cd -- "$dir"
		return $?
	fi
}

#!/usr/bin/env bash
# .bashrc

# if not running interactively, don't do anything
[[ -z $PS1 ]] && return

if [[ -n $VTE_VERSION ]]; then

	if [[ -f '/opt/vte-ng-v0.46.0.a-git/etc/profile.d/vte.sh' ]]; then
		. '/opt/vte-ng-v0.46.0.a-git/etc/profile.d/vte.sh'
	elif [[ -f '/etc/profile.d/vte.sh' ]]; then
		. '/etc/profile.d/vte.sh'
	elif [[ -f '/usr/local/etc/profile.d/vte.sh' ]]; then
		. '/usr/local/etc/profile.d/vte.sh'
	else
		echo 'vte.sh not found' 1>&2
	fi

	__term_name_prefix=$([[ $TERM == xterm-termite ]] && printf 'termite | ')
	__custom_vte_prompt_command() {
		printf '%s' "$(__vte_prompt_command)" \
			| perl -pe \
				'BEGIN { $x=@ARGV[0]; @ARGV=() }; s/0;/0;$x/' \
				-- "$__term_name_prefix"
	}

	export TERM=xterm-256color
fi

if which nvim 0</dev/null 1>/dev/null 2>/dev/null; then
	export EDITOR=nvim
elif which vim 0</dev/null 1>/dev/null 2>/dev/null; then
	export EDITOR=vim
elif which nano 0</dev/null 1>/dev/null 2>/dev/null; then
	export EDITOR=nano
fi

# don't put duplicate lines in the history
export HISTCONTROL=ignoreboth:erasedups

# set history length
HISTFILESIZE=1000000000
HISTSIZE=1000000

# append to the history file, don't overwrite it
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry (allows easy re-editing of multi-line commands)
shopt -s cmdhist
# cd to a directory by typing its name
shopt -s autocd

__MY_BASHRC_CONFIGS_DIR=$(dirname -- "`readlink -f -- "${BASH_SOURCE[0]}"`")

. "$__MY_BASHRC_CONFIGS_DIR/utils/tmux-cd.sh"
. "$__MY_BASHRC_CONFIGS_DIR/utils/cwd-abs-to-rel.sh"

__PERL_PROMPT_CMD=$(cat -- "$__MY_BASHRC_CONFIGS_DIR/utils/prompt-cmd.pl")

cwd-abs-to-rel

if [[ -f ~/.hostname ]]; then
	LOCAL_HOSTNAME=`cat ~/.hostname`
else
	LOCAL_HOSTNAME=$HOSTNAME
fi

function __perl {
	perl \
		-e 'use v5.10;' \
		-e 'use Env qw(USER);' \
		-e 'use Term::ANSIColor qw(:constants);' \
		-e 'use IPC::System::Simple qw(capturex);' \
		-e 'use constant UID => (getpwnam $USER)[2];' \
		"$@"
}

__UID=`id -u`

# permission symbol
__perm_symbol=
case "$__UID" in
	# TODO FIXME colors adds buggy cursor shift when listing history
	# 0) __perm_symbol=$(__perl -e 'print RED,   q{#}, RESET') ;;
	# *) __perm_symbol=$(__perl -e 'print GREEN, q{$}, RESET') ;;
	# TODO remove this temporary solution
	0) __perm_symbol='#' ;;
	*) __perm_symbol='$' ;;
esac

function prompt_command {

	PS1=$(
		perl -e "$__PERL_PROMPT_CMD" -- \
			"$USER" "$__UID" "$HOME" "$PWD" \
			"$LOCAL_HOSTNAME" "$VIRTUAL_ENV" "$COLUMNS"
	)

	[[ -n $VTE_VERSION ]] && __custom_vte_prompt_command
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command
# set new b/w prompt (will be overwritten in 'prompt_command' later)
# TODO FIXME colors adds buggy cursor shift when listing history
# PS1=$(__perl \
# 	-e 'BEGIN { $HOSTNAME=$ARGV[0]; $__perm_symbol=$ARGV[1]; @ARGV=() };' \
# 	-e 'print (((UID == 0) ? RED : GREEN), q{\u}, RESET);' \
# 	-e 'print q{@}, YELLOW, $HOSTNAME, RESET, q{:};' \
# 	-e 'print BLUE, q{\w}, RESET, q{\n}, $__perm_symbol, q{ };' \
# 	-- "$LOCAL_HOSTNAME" "$__perm_symbol"
# )
# TODO remove this temporary solution
PS1=$(__perl \
	-e 'BEGIN { $HOSTNAME=$ARGV[0]; $__perm_symbol=$ARGV[1]; @ARGV=() };' \
	-e 'print (((UID == 0) ? RED : GREEN), q{\u}, RESET);' \
	-e 'print q{@}, YELLOW, $HOSTNAME, RESET, q{:};' \
	-e 'print BLUE, q{\w}, RESET, q{\n}, $__perm_symbol, q{ };' \
	-- "$LOCAL_HOSTNAME" "$__perm_symbol"
)

# Postgres won't work without this
export PGHOST=/tmp

# this is for delete words by ^W
tty -s && stty werase ^- 2>/dev/null

bind 'set show-all-if-ambiguous on'
bind '"\C-n":menu-complete'
bind '"\C-p":menu-complete-backward'

# silently spawn an application in background
function _burp_completion {
	local cur=${COMP_WORDS[COMP_CWORD]}
	COMPREPLY=($(compgen -A function -abck -- "$cur"))
}
complete -F _burp_completion -o default burp

if [[ -z $_JAVA_OPTIONS ]]; then
	export _JAVA_OPTIONS='
		-Dawt.useSystemAAFontSettings=on
		-Dswing.aatext=true
		-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel
		-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel
	'
fi

[[ -z $_JAVA_AWT_WM_NONREPARENTING ]] && export _JAVA_AWT_WM_NONREPARENTING=1

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# vim: set noet cc=81 tw=80 :

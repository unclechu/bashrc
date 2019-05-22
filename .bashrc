#!/usr/bin/env bash
# .bashrc

# if isn't running interactively, don't do anything
[[ -z $PS1 ]] && return

if [[ -n $VTE_VERSION ]]; then

	if [[ -f /usr/local/etc/profile.d/vte.sh ]]; then
		. /usr/local/etc/profile.d/vte.sh
	elif [[ -f /etc/profile.d/vte.sh ]]; then
		. /etc/profile.d/vte.sh
	else
		echo 'vte.sh not found' 1>&2
	fi

	if [[ -z $__term_name_prefix ]] && [[ $TERM == xterm-termite ]]; then
		export __term_name_prefix='termite | '
	fi

	__custom_vte_prompt_command() {
		local cmd=$1
		[[ -n $cmd ]] && cmd="$cmd | "

		perl -e '
			BEGIN { $_=$ARGV[0]; $term=$ARGV[1]; $cmd=$ARGV[2]; @ARGV=() };
			s/0;/0;$term$cmd/;
			print;
		' -- "$(__vte_prompt_command)" "$__term_name_prefix" "$cmd"
	}

	export TERM=screen-256color

elif env | grep '^KONSOLE_' 1>/dev/null; then

	export TERM=screen-256color
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
# check the window size after each command and,
# if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry
# (allows easy re-editing of multi-line commands).
shopt -s cmdhist
# cd to a directory by typing its name
shopt -s autocd
# regex-style pattern matching
shopt -s extglob

LOCAL_HOSTNAME=$([[ -f ~/.hostname ]] && \
	printf '%s' "`cat ~/.hostname`" || printf '%s' "$HOSTNAME")

__MY_BASHRC_CONFIG_DIR=$(dirname -- "`readlink -f -- "${BASH_SOURCE[0]}"`")
__UID=`id -u`

coproc __COPROC { "$__MY_BASHRC_CONFIG_DIR/coproc.pl"; }

# $1 - end marker
__read_from_coproc() {

	local task=$1

	while (( $# > 0 )); do
		printf '%s\n' "$1" >&${__COPROC[1]}
		shift
	done

	while IFS= read -ru ${__COPROC[0]} x; do
		[[ $x == "~~ end of $task ~~" ]] && break
		printf '%s' "$x"
	done
}

# changing dir at bash session start for tmux new panes/windows
if [[ -n $TMUX ]]; then
	__tmux_cd=$(tmux showenv _TMUX_CD 2>/dev/null)
	if (( $? == 0 )) && [[ -n $__tmux_cd ]]; then
		__tmux_cd=$(
			printf '%s' "$__tmux_cd" | perl -pe 's/^_TMUX_CD=//' 2>/dev/null
		)
		if (( $? == 0 )) && [[ -n $__tmux_cd ]] && [[ -d $__tmux_cd ]]; then
			cd -- "$__tmux_cd"
		fi
	fi
	unset __tmux_cd
fi

__relative_path=`__read_from_coproc get-relative-path "$PWD" "$USER" "$HOME"`
[[ -n $__relative_path ]] && cd -- "$__relative_path"
unset __relative_path

if [[ -n $VTE_VERSION ]]; then
	trap '__custom_vte_prompt_command "${BASH_COMMAND%% *}"' DEBUG
fi

prompt_command() {
	PS1=$(__read_from_coproc get-ps1 \
		"$USER" "$__UID" "$HOME" "$PWD" "$LOCAL_HOSTNAME" \
		"$VIRTUAL_ENV" "$COLUMNS" "$?")

	[[ -n $VTE_VERSION ]] && __custom_vte_prompt_command
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command

# set new b/w prompt (will be overwritten in 'prompt_command' later)
PS1=`__read_from_coproc get-static-ps1 "$__UID" "$LOCAL_HOSTNAME"`

# this is for delete words by ^W
tty -s && stty werase ^- 2>/dev/null

bind 'set show-all-if-ambiguous on'
bind '"\C-n":menu-complete'
bind '"\C-p":menu-complete-backward'

# silently spawn an application in background
_burp_completion() {
	local cur=${COMP_WORDS[COMP_CWORD]}
	COMPREPLY=($(compgen -A function -abck -- "$cur"))
}
complete -F _burp_completion -o default burp

# pip bash completion start
_pip_completion() {
	COMPREPLY=($( \
		COMP_WORDS="${COMP_WORDS[*]}" COMP_CWORD=$COMP_CWORD \
		PIP_AUTO_COMPLETE=1 $1))
}
complete -o default -F _pip_completion pip
# pip bash completion end

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

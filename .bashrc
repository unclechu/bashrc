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

	# support colors
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

. "$__MY_BASHRC_CONFIGS_DIR/utils/colors.sh"
. "$__MY_BASHRC_CONFIGS_DIR/utils/tmux-cd.sh"
. "$__MY_BASHRC_CONFIGS_DIR/utils/cwd-abs-to-rel.sh"

cwd-abs-to-rel

if [[ -f ~/.hostname ]]; then
	LOCAL_HOSTNAME=`cat ~/.hostname`
else
	LOCAL_HOSTNAME=$HOSTNAME
fi

# permission symbol
perm_symbol=
case "`id -u`" in
	0) perm_symbol="${color_red}#${color_off}"    ;;
	*) perm_symbol="${color_green}\$${color_off}" ;;
esac

function prompt_command {
	local pwdname=$PWD
	local remote=false
	local ps1_remote=
	local pyvenv_name=
	local pyvenv_chars=

	# beautify working directory name
	if [[ $HOME == $PWD ]]; then
		pwdname='~'
	elif [[ $HOME == ${PWD:0:${#HOME}} ]]; then
		pwdname="~${PWD:${#HOME}}"
	fi

	# detect remote mount
	df -l -- "$PWD" 1>/dev/null 2>/dev/null
	if (( $? == 1 )); then
		remote=true
		ps1_remote=" (remote)"
	fi

	if [[ -n $VIRTUAL_ENV ]]; then
		pyvenv_name=$(basename -- "$VIRTUAL_ENV" "$(dirname -- "$VIRTUAL_ENV")")
		pyvenv_chars="(pyvenv: $pyvenv_name) "
		pyvenv_name="(pyvenv: ${color_purple}${pyvenv_name}${color_off}) "
	fi

	# calculate prompt length
	local ps1_length=$((${#pyvenv_chars}+${#USER}+
		${#LOCAL_HOSTNAME}+${#pwdname}+${#ps1_remote}+3))
	local fill=

	# if length is greater, than terminal width
	if (( $ps1_length > $COLUMNS )); then
		# strip working directory name
		pwdname="...${pwdname:$(($ps1_length-$COLUMNS+3))}"
	else
		# else calculate fillsize
		local fillsize=$(($COLUMNS - $ps1_length))
		fill=$color_white
		while (( $fillsize > 0 )); do
			fill="${fill}─"
			fillsize=$(($fillsize - 1))
		done
		fill="${fill}${color_off}"
	fi

	if [[ $color_is_on == true && $remote == true ]]; then
		ps1_remote=" (${color_red}remote${color_off})"
	fi

	# set new color prompt
	PS1="${pyvenv_name}${color_user}${USER}${color_off}"
	PS1="${PS1}@${color_yellow}${LOCAL_HOSTNAME}${color_off}"
	PS1="${PS1}:${color_blue}${pwdname}${color_off}"
	PS1="${PS1}${ps1_remote}"
	PS1="${PS1} ${fill}\n${perm_symbol} "

	[[ -n $VTE_VERSION ]] && __custom_vte_prompt_command
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command
# set new b/w prompt (will be overwritten in 'prompt_command' later for color prompt)
PS1="${color_user}\u${color_off}"
PS1="${PS1}@${color_yellow}${LOCAL_HOSTNAME}${color_off}:"
PS1="${PS1}${color_blue}\w${color_off}\n"
PS1="${PS1}${perm_symbol} "

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

# vim: set noet :

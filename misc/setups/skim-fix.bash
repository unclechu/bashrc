#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE
# shellcheck disable=SC2016

# A fix for glitching rendering of Skim.
# Just a copy-paste of the key-bindings for Skim for older Bash (<4 version).
# UPD: Actually used my own bindings, as the previous attempt to fix didn’t work
# well.

# CTRL-T - Paste the selected file path into the command line
# bind -m emacs-standard '"\C-t": " \C-b\C-k \C-u`__skim_select__`\e\C-e\er\C-a\C-y\C-h\C-e\e \C-y\ey\C-x\C-x\C-f"'
# bind -m vi-command '"\C-t": "\C-z\C-t\C-z"'
# bind -m vi-insert '"\C-t": "\C-z\C-t\C-z"'
# My own customized/simplified “__skim_select__” implementation
__my_skim_select__() {
	local cmd
	cmd="${SKIM_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune -o -type f -print -o -type d -print -o -type l -print 2> /dev/null | cut -b3-"}"

	local sk_cmd
	if [[ ! -v NO_TMUX_F || -z $NO_TMUX_F ]] && [[ -v TMUX && -n $TMUX ]]; then
		sk_cmd=(sk --tmux 'center,80%,60%')
	else
		sk_cmd=(sk)
	fi

	eval -- "$cmd" | "${sk_cmd[@]}" | while read -r x; do printf %q "$x"; done
	echo
}
bind -m vi-insert '"\C-t": "\C-u$(__my_skim_select__)\C-x\C-e "'
bind -m vi-command '"\C-t": "\C-u$(__my_skim_select__)\C-x\C-e "'

# CTRL-R - Paste the selected command from history into the command line
# bind -m emacs-standard '"\C-r": "\C-e \C-u\C-y\ey\C-u"$(__skim_history__)"\e\C-e\er"'
# bind -m vi-command '"\C-r": "\C-z\C-r\C-z"'
# bind -m vi-insert '"\C-r": "\C-z\C-r\C-z"'
# WARNING! Depends on the “hf” alias (see misc/aliases/skim.bash)
bind -m vi-insert '"\C-r": "\C-u$(hf)\C-x\C-e "'
bind -m vi-command '"\C-r": "\C-u$(hf)\C-x\C-e "'

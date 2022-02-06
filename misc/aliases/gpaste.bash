#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Shortcut for GPaste CLI
alias gp=$(
	if   [[ -x $(type -P gpaste-client 2>/dev/null) ]]; then echo 'gpaste-client'
	elif [[ -x $(type -P gpaste        2>/dev/null) ]]; then echo 'gpaste'
	else echo 'echo gpaste not found >&2 ; false'
	fi
)

# Copy to system clipboard without any line breaks (“i” for “inline”).
alias gpi='perl -pe chomp | gp'

# Suspend GPaste temporarily until current program exits.
# For instance can be useful when copying and pasting password, to avoid them
# getting into the clipboard history.
# Can be used in a subprogram like this:
#   (suspend-gp && keepassx)
alias suspend-gp='trap "gp start; gp get --use-index 0 | gp" EXIT && gp stop'

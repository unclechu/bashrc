#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# shortcut for gpaste cli
alias gp=$(
	if   [[ -x $(type -P gpaste-client 2>/dev/null) ]]; then echo 'gpaste-client'
	elif [[ -x $(type -P gpaste        2>/dev/null) ]]; then echo 'gpaste'
	else echo 'echo gpaste not found >&2 ; false'
	fi
)

# Copy to system clipboard without any line breaks (“i” for “inline”).
alias gpi='perl -pe chomp | gp'

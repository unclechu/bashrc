#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

_pip_completion() {
	COMPREPLY=($(
		COMP_WORDS="${COMP_WORDS[*]}" COMP_CWORD=$COMP_CWORD \
		PIP_AUTO_COMPLETE=1 $1
	))
}

complete -o default -F _pip_completion pip

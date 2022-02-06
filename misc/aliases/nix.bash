#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

alias setup-nix='. ~/.nix-profile/etc/profile.d/nix.sh'

# nix-shell with forwarded $SHELL
alias nsh=$(
	echo -n "nix-shell --command '"
	echo -n $'export SHELL=\'"\'${SHELL//\\\'}\'"\' && "$SHELL"'
	echo -n "'"
)

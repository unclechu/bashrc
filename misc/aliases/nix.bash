#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

alias setup-nix='. ~/.nix-profile/etc/profile.d/nix.sh'

# nix-shell with forwarded $SHELL
alias nsh='nix-shell --command "export SHELL=${SHELL@Q} && ${SHELL@Q}"'

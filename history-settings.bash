#! /usr/bin/env bash
#
# history-settings.bash
#
# Note for NixOS or just Nix:
# Sourcing this file in your ~/.bashrc (in your home directory) will help to fix
# lost history items after running regular bash shell (not "wenzels-bash").
#
# You can source it using Home Manager in your "configuration.nix" like this:
#   home-manager.users.john.home.file.".bashrc".text = ''
#     . ${pkgs.lib.escapeShellArg wenzels-bash.history-settings-file-path}
#   '';
#
# See https://github.com/unclechu/nixos-config for an example.

# don't put duplicate lines in the history
HISTCONTROL=ignoreboth:erasedups

# set history length
HISTFILESIZE=1000000000
HISTSIZE=1000000

# append to the history file, don't overwrite it
shopt -s histappend

# show command from history before execute it
shopt -s histverify

# save all lines of a multiple-line command in the same history entry
# (allows easy re-editing of multi-line commands).
shopt -s cmdhist

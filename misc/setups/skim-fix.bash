#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# A fix for glitching rendering of Skim.
# Just a copy-paste of the key-bindings for Skim for older Bash (<4 version).

# CTRL-T - Paste the selected file path into the command line
bind -m emacs-standard '"\C-t": " \C-b\C-k \C-u`__skim_select__`\e\C-e\er\C-a\C-y\C-h\C-e\e \C-y\ey\C-x\C-x\C-f"'
bind -m vi-command '"\C-t": "\C-z\C-t\C-z"'
bind -m vi-insert '"\C-t": "\C-z\C-t\C-z"'

# CTRL-R - Paste the selected command from history into the command line
bind -m emacs-standard '"\C-r": "\C-e \C-u\C-y\ey\C-u"$(__skim_history__)"\e\C-e\er"'
bind -m vi-command '"\C-r": "\C-z\C-r\C-z"'
bind -m vi-insert '"\C-r": "\C-z\C-r\C-z"'

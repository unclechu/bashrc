#! /usr/bin/env bash

# $1 - encrypted file
#
# $2 - a shell command to do something with encrypted file where
#      $f is the encrypted filename (from $1 argument),
#      $d is the directory of original $1 file,
#      $t is new temporary directory where decrypted file $f is saved,
#      working directory is changed to $t so you are free to mess there and all
#      this will be cleaned up when this shell command is done.
#
# [$3] - optional [--silent|-s] flag which silents boilerplate noise
#        but keeps stderr output inside shell command from $2 argument
#
tmpgpg() {
	if (( $# < 2 || $# > 3 )) || [[ -z $1 || ! -f $1 ]]; then
		>&2 echo \
			Incorrect arguments! Provide encrypted file and a shell command!
		return 1
	fi
	local FILE_DIR; FILE_DIR=$(dirname -- "$1") || return
	local ENCRYPTED_FILE; ENCRYPTED_FILE=$(basename -- "$1"); shift || return
	local CMD; CMD=$1; shift || return
	local OPT IS_SILENT=NO; if (( $# > 0 )); then
		OPT=$1; shift || return
		IS_SILENT=$(
			if [[ $OPT == '-s' || $OPT == --silent ]];
			then echo YES;
			else ( >&2 printf 'Unexpected option: "%s"\n' "$OPT" && return 1 )
			fi
		) || return
	fi
	if (( $# != 0 )); then
		>&2 echo "Some ($#) arguments left unparsed!"
		return 1
	fi
	(
		cd -- "$FILE_DIR" || return
		local FILE_DIR_PWD; FILE_DIR_PWD=$PWD || return
		local TMPDIR; TMPDIR=$(mktemp -d --suffix="-$ENCRYPTED_FILE") || return
		local CLEANUP; CLEANUP=$(
			if [[ $IS_SILENT == YES ]]; then echo -n 'exec 2>/dev/null ;'; fi
			echo -n $'find "$TMPDIR/" -type f -exec shred -vufz -n10 {} \;'
			echo -n ';find "$TMPDIR/" -type d | tac | xargs rmdir'
		) || return
		trap -- "$CLEANUP" EXIT || return
		(
			if [[ $IS_SILENT == YES ]]; then exec 2>/dev/null; fi
			gpg -d -o "$TMPDIR/$ENCRYPTED_FILE" -- "$ENCRYPTED_FILE" || return
		)
		cd -- "$TMPDIR" || return
		if [[ $IS_SILENT == NO ]]; then
			>&2 echo \
				'~~~~~~~~~~~~~~~~ RUNNING THE SHELL COMMAND ~~~~~~~~~~~~~~~~~'
		fi
		local SHELL_CMD; SHELL_CMD=$(
			echo 'if [[ -n $BASH_DIR_PLACEHOLDER ]]; then'
			echo '  . "$BASH_DIR_PLACEHOLDER"/.bash_aliases || exit'
			echo 'elif [[ -f ~/.bash_aliases ]]; then'
			echo '  . ~/.bash_aliases || exit'
			echo 'fi'
			echo 'set -x || exit'
			printf %s "$CMD"
		) || return
		f=$ENCRYPTED_FILE d=$FILE_DIR_PWD t=$TMPDIR \
			"$SHELL" -c "$SHELL_CMD" || return
		if [[ $IS_SILENT == NO ]]; then
			>&2 echo \
				'~~~~~~~~~~~~~~~~~~~~~~~~~~~ DONE ~~~~~~~~~~~~~~~~~~~~~~~~~~~'
		fi
	)
}

#! /usr/bin/env bash
# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Call with '--help' to see the usage info
tmpgpg() (
	set -Eeuo pipefail || exit

	show-usage() {
		set -Eeuo pipefail || exit

		local USAGE_INFO; declare -A USAGE_INFO=(
			['1|ENCRYPTED_FILE']='Encrypted file'
			['2|SHELL_COMMAND']='
				A shell command to do something with encrypted file where
				$f is encrypted filename (from ENCRYPTED_FILE argument),
				$d is directory of original ENCRYPTED_FILE,
				$t is temporary directory where decrypted $f is saved to.
				Working directory is changed to $t so that you are free to
				mess there and all this will be cleaned up when this shell
				command is done.
				'
			['3|[OPTION]']='
				Optional [--silent|-s] flag which silents boilerplate noise
				but keeps stderr output inside shell command from
				SHELL_COMMAND argument. Alternative to --silent is
				[--quiet|-q] which also disables commands logging (set -x)
				for the SHELL_COMMAND as well.
				'
		)

		local args; args=$(printf '%s\n' "${!USAGE_INFO[@]}" | sort)
		readarray -t args <<< "$args"
		printf '\nUsage: %s %s\n\n' "${FUNCNAME[1]}" "${args[*]//[0-9]|/}"
		printf 'Arguments:\n\n'
		local arg_name arg_printed arg_description
		for arg_name in "${args[@]}"; do
			arg_printed='              '
			arg_description=$(
				sed '1{/^\s*$/d}' <<< "${USAGE_INFO[$arg_name]}" \
					| sed -e '1{s/^\s\+//};' -e '${/^\s\+$/d}' \
						-e "s/^\s\+/  $arg_printed  /"
			)
			arg_name=${arg_name//[0-9]|/}
			arg_name=${arg_name//[\[\]]/}
			arg_printed=${arg_name}${arg_printed:${#arg_name}}
			printf '  %s  %s\n\n' "$arg_printed" "$arg_description"
		done
	}

	if (( $# == 1 )) && [[ $1 == --help || $1 == '-h' ]]; then
		show-usage
		return 0
	elif (( $# < 2 || $# > 3 )) || [[ -z $1 || ! -f $1 ]]; then
		>&2 echo Incorrect arguments!
		show-usage
		return 1
	fi

	local FILE_DIR; FILE_DIR=$(dirname -- "$1")
	local ENCRYPTED_FILE; ENCRYPTED_FILE=$(basename -- "$1"); shift
	local CMD; CMD=$1; shift

	local OPT IS_SILENT=NO IS_QUIET=NO; if (( $# > 0 )); then
		OPT=$1; shift
		if [[ $OPT == '-s' || $OPT == --silent ]]; then
			IS_SILENT=YES
		elif [[ $OPT == '-q' || $OPT == --quiet ]]; then
			IS_SILENT=YES
			IS_QUIET=YES
		else
			( >&2 printf 'Unexpected option: "%s"\n' "$OPT" && return 1 )
		fi
	fi

	if (( $# != 0 )); then
		>&2 printf 'Some (%d) arguments left unparsed!' "$#"
		return 1
	fi

	(
		cd -- "$FILE_DIR"
		local FILE_DIR_PWD; FILE_DIR_PWD=$PWD
		local TMPDIR; TMPDIR=$(mktemp -d --suffix="-$ENCRYPTED_FILE")

		local CLEANUP; CLEANUP=$(
			set -Eeuo pipefail || exit
			if [[ $IS_SILENT == YES ]]; then echo -n 'exec 2>/dev/null ;'; fi
			echo -n $'find "$TMPDIR/" -type f -exec shred -vufz -n10 {} \;'
			echo -n ';find "$TMPDIR/" -type d | tac | xargs rmdir'
		)

		trap -- "$CLEANUP" EXIT
		(
			if [[ $IS_SILENT == YES ]]; then exec 2>/dev/null; fi
			gpg -d -o "$TMPDIR/$ENCRYPTED_FILE" -- "$ENCRYPTED_FILE"
		)
		cd -- "$TMPDIR"
		if [[ $IS_SILENT == NO ]]; then
			>&2 echo \
				'~~~~~~~~~~~~~~~~ RUNNING THE SHELL COMMAND ~~~~~~~~~~~~~~~~~'
		fi
		local SHELL_CMD; SHELL_CMD=$(
			set -Eeuo pipefail || exit
			echo 'if [[ -n $BASH_DIR_PLACEHOLDER ]]; then'
			echo '  . "$BASH_DIR_PLACEHOLDER"/.bash_aliases || exit'
			echo 'elif [[ -f ~/.bash_aliases ]]; then'
			echo '  . ~/.bash_aliases || exit'
			echo 'fi'
			if [[ $IS_QUIET == NO  ]]; then echo 'set -x || exit'; fi
			if [[ $IS_QUIET == YES ]]; then echo 'set +x || exit'; fi
			printf %s "$CMD"
		)
		f=$ENCRYPTED_FILE d=$FILE_DIR_PWD t=$TMPDIR "$SHELL" -c "$SHELL_CMD"
		if [[ $IS_SILENT == NO ]]; then
			>&2 echo \
				'~~~~~~~~~~~~~~~~~~~~~~~~~~~ DONE ~~~~~~~~~~~~~~~~~~~~~~~~~~~'
		fi
	)
)

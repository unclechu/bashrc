#! /usr/bin/env bash
# .bashrc

# if isn't running interactively, don't do anything
if [[ -z $PS1 ]]; then return; fi

declare -A __COLOR
# padded with zeroes to be able to cut off colors using native bash replace
# (bash replace just has some regex features but it's not a real regex)
__COLOR=(
	[RESET]='\[\e[000m\]' [BOLD]='\[\e[001m\]' [DARK]='\[\e[002m\]'
	[ITALIC]='\[\e[003m\]' [UNDERLINE]='\[\e[004m\]' [BLINK]='\[\e[005m\]'
	[REVERSE]='\[\e[007m\]' [CONCEALED]='\[\e[008m\]'

	[BLACK]='\[\e[030m\]'   [ON_BLACK]='\[\e[040m\]'
	[RED]='\[\e[031m\]'     [ON_RED]='\[\e[041m\]'
	[GREEN]='\[\e[032m\]'   [ON_GREEN]='\[\e[042m\]'
	[YELLOW]='\[\e[033m\]'  [ON_YELLOW]='\[\e[043m\]'
	[BLUE]='\[\e[034m\]'    [ON_BLUE]='\[\e[044m\]'
	[MAGENTA]='\[\e[035m\]' [ON_MAGENTA]='\[\e[045m\]'
	[CYAN]='\[\e[036m\]'    [ON_CYAN]='\[\e[046m\]'
	[WHITE]='\[\e[037m\]'   [ON_WHITE]='\[\e[047m\]'

	[BRIGHT_BLACK]='\[\e[090m\]'   [ON_BRIGHT_BLACK]='\[\e[100m\]'
	[BRIGHT_RED]='\[\e[091m\]'     [ON_BRIGHT_RED]='\[\e[101m\]'
	[BRIGHT_GREEN]='\[\e[092m\]'   [ON_BRIGHT_GREEN]='\[\e[102m\]'
	[BRIGHT_YELLOW]='\[\e[093m\]'  [ON_BRIGHT_YELLOW]='\[\e[103m\]'
	[BRIGHT_BLUE]='\[\e[094m\]'    [ON_BRIGHT_BLUE]='\[\e[104m\]'
	[BRIGHT_MAGENTA]='\[\e[095m\]' [ON_BRIGHT_MAGENTA]='\[\e[105m\]'
	[BRIGHT_CYAN]='\[\e[096m\]'    [ON_BRIGHT_CYAN]='\[\e[106m\]'
	[BRIGHT_WHITE]='\[\e[097m\]'   [ON_BRIGHT_WHITE]='\[\e[107m\]'
)

# use it to remove color symbols like this: ${x//$__COLOR_PATTERN/}
__COLOR_PATTERN='\\\[[[:cntrl:]]\[[[:digit:]][[:digit:]][[:digit:]]m\\\]'

if [[ -z $__TERM_NAME_PREFIX && $TERM == xterm-termite ]]; then
	export __TERM_NAME_PREFIX='termite | '
fi

if [[ -n $VTE_VERSION ]]; then
	if [[ -z $VIMRUNTIME ]]; then
		if ! . '/usr/local/etc/profile.d/vte.sh' 2>/dev/null; then
			. '/etc/profile.d/vte.sh' 2>/dev/null
		fi

		if (( $? != 0 )); then
			echo '[ERROR] vte.sh not found!' >&2
			__vte_prompt_command() { return 1; }
		fi

		__custom_vte_prompt_command() {
			local PROMPT; PROMPT=$(__vte_prompt_command 2>/dev/null)

			if (( $? == 0 )); then
				local cmd=$(if [[ -n $1 ]]; then printf '%s | ' "$1"; fi)
				printf '%s' "${PROMPT/0;/0;${__TERM_NAME_PREFIX}${cmd}}"
			fi
		}
	fi

	export TERM=screen-256color

elif [[ -n $KONSOLE_VERSION ]]; then
	export TERM=screen-256color
fi

export EDITOR=$(
	# better to predefine it in a file to reduce startup time
	if cat ~/.editor 2>/dev/null; then :
	elif [[ -x $(type -P nvim 2>/dev/null) ]]; then echo nvim
	elif [[ -x $(type -P vim  2>/dev/null) ]]; then echo vim
	elif [[ -x $(type -P vi   2>/dev/null) ]]; then echo vi
	elif [[ -x $(type -P nano 2>/dev/null) ]]; then echo nano
	fi
)

# history settings block {{{
__MY_BASH_CONFIG_DIR=$(dirname -- "${BASH_SOURCE[0]}") || exit
. "$__MY_BASH_CONFIG_DIR"/history-settings.bash || exit
unset __MY_BASH_CONFIG_DIR || exit
# history settings block }}}

# check the window size after each command and,
# if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# cd to a directory by typing its name
shopt -s autocd
# regex-style pattern matching
shopt -s extglob

LOCAL_HOSTNAME=$(
	if [[ -f ~/.hostname ]]; then
		cat ~/.hostname
	else
		printf '%s' "$HOSTNAME"
	fi
)


# changing dir at bash session start for tmux new panes/windows
if [[ -n $TMUX ]]; then
	__tmux_cd=$(tmux showenv _TMUX_CD 2>/dev/null)
	if (( $? == 0 )) && [[ -n $__tmux_cd ]]; then
		__tmux_cd=${__tmux_cd#_TMUX_CD=}
		if (( $? == 0 )) && [[ -n $__tmux_cd ]] && [[ -d $__tmux_cd ]]; then
			cd -- "$__tmux_cd"
		fi
	fi
	unset __tmux_cd
fi


__docker_dev_pattern="^/mnt/([0-9A-Za-z_-]+)/docker/${USER}-dev(/|$)"

__relative_path_patterns=(
	"^/run/media/${USER}/([0-9A-Za-z_-]+)/(home/)?${USER}(/|$)"
	"^/media/${USER}/([0-9A-Za-z_-]+)/(home/)?${USER}(/|$)"
	"^/media/([0-9A-Za-z_-]+)/(home/)?${USER}/(/|$)"
	"^/mnt/([0-9A-Za-z_-]+)/(home/)?${USER}(/|$)"
	"$__docker_dev_pattern"
	"^/usr/home/${USER}(/|$)"
)

for pattern in "${__relative_path_patterns[@]}"; do
	if ! [[ $PWD =~ $pattern ]]; then continue; fi
	__pwd_inode=$(stat -c %i -- "$PWD")

	__to_cd=$({
		TAIL=${PWD:${#BASH_REMATCH[0]}}
		MNT_NAME=${BASH_REMATCH[1]}
		if [[ -n $TAIL ]]; then TAIL=/$TAIL; fi

		NEW_WD=$(
			if [[ $PWD =~ $__docker_dev_pattern ]]; then
				printf '%s%s' "$HOME" "$TAIL"
			else
				printf '%s/%s%s' "$HOME" "$MNT_NAME" "$TAIL"
			fi
		)

		if [[ ! -d $NEW_WD ]] ||
		(( $__pwd_inode != $(stat -c %i -- "$NEW_WD") )); then
			printf '✗'
			return 0
		fi

		SHORT_NEW_WD=${HOME}${TAIL}

		if [[ -d "$SHORT_NEW_WD" ]] &&
		(( $__pwd_inode == $(stat -c %i -- "$SHORT_NEW_WD") )); then
			printf '%s' "$SHORT_NEW_WD"
		else
			printf '%s' "$NEW_WD"
		fi
	})

	break
done

if [[ $__to_cd == '✗' ]]; then
	:
elif [[ -n $__to_cd ]]; then
	cd -- "$__to_cd"
elif (( ${#PWD} > ${#HOME} )) && [[ $PWD =~ ^$HOME ]]; then
	__to_cd=$({
		WD_TAIL=${PWD:$((${#HOME} + 1))}
		if [[ -z $WD_TAIL ]]; then return 0; fi

		IFS='/' read -r -a WD_TAIL_A <<< "$WD_TAIL"
		WD_TAIL_A=(${WD_TAIL_A[@]:1})

		WD_SLICED=${HOME}$(printf '/%s' "${WD_TAIL_A[@]}")
		if [[ $WD_SLICED == ${HOME}/ ]]; then WD_SLICED=$HOME; fi

		if [[ -z $__pwd_inode ]]; then
			__pwd_inode=$(stat -c %i -- "$PWD")
		fi

		if [[ ! -d $WD_SLICED ]] ||
		(( $__pwd_inode != $(stat -c %i -- "$WD_SLICED") )); then
			return 0
		fi

		printf '%s' "$WD_SLICED"
	})

	if [[ -n $__to_cd ]]; then cd -- "$__to_cd"; fi
fi

unset __docker_dev_pattern __relative_path_patterns __pwd_inode __to_cd


if [[ -n $VTE_VERSION && -z $VIMRUNTIME ]]; then
	trap '__custom_vte_prompt_command "${BASH_COMMAND%% *}"' DEBUG
fi

declare -A __PERMISSION
__PERMISSION[COLOR]=$(
	if (( $UID == 0 )); then
		printf '%b' "${__COLOR[RED]}"
	else
		printf '%b' "${__COLOR[GREEN]}"
	fi
)
__PERMISSION[MARK]=$(
	printf '%b%s%b' "${__PERMISSION[COLOR]}" "$(
		if (( $UID == 0 )); then echo 'α'; else echo 'λ'; fi
	)" "${__COLOR[RESET]}"
)

prompt_command() {
	local RETVAL=$?

	local PWD_VIEW; PWD_VIEW=$(
		if [[ $PWD =~ ^$HOME ]]; then
			printf '~%s' "${PWD#$HOME}"
		else
			printf  '%s' "$PWD"
		fi
	)

	# Detecting remote mount point
	local REMOTE_VIEW; REMOTE_VIEW=$({
		DF=$(df -l -T -- "$PWD" 2>/dev/null)
		if (( $? == 1 )); then # works on gnu/linux
			:
		else
			# works on freebsd
			REG=$'^[^\n]+\n'"[^ ]+[ ]+fusefs(\.|[ ]+)"
			if ! [[ $DF =~ $REG ]]; then return 0; fi
		fi
		printf ' (%bremote%b)' "${__COLOR[RED]}" "${__COLOR[RESET]}"
	})

	local NIX_SHELL_VIEW; NIX_SHELL_VIEW=$(
		if [[ -n $IN_NIX_SHELL ]]; then
			printf '(%bnix-shell%b) ' "${__COLOR[BLUE]}" "${__COLOR[RESET]}"
		fi
	)

	local PYVENV_VIEW; PYVENV_VIEW=$(
		if [[ -n $VIRTUAL_ENV ]]; then
			printf '(pyvenv: %b%s%b) ' \
				"${__COLOR[MAGENTA]}" "${VIRTUAL_ENV##*/}" "${__COLOR[RESET]}"
		fi
	)

	local ABOUT_FINAL_NEWLINE; ABOUT_FINAL_NEWLINE=$(
		# See https://stackoverflow.com/a/2575525
		# Requesting cursor position in background with delay to reduce glitches
		# when reading is being late and response is shown on the screen
		# instead of being read.
		{ sleep .05s; >/dev/tty echo -en '\E[6n'; } & # Request cursor position
		</dev/tty read -sdR CURPOS # Retrieve cursor position
		CURCOL=${CURPOS#*;} # Extract cursor column

		if (( $CURCOL > 1 )); then
			MSG=(
				"${__COLOR[ITALIC]}${__COLOR[RED]}"
				$'↴\nThere was no final newline!\n'
				"${__COLOR[RESET]}"
			)
			printf '%b' "${MSG[@]}"
		fi
	)

	local PS1_PRE; PS1_PRE=$(
		printf '%s%s%b%b%s%s%b %b%s%b@%b%s%b:' \
			"$NIX_SHELL_VIEW" \
			"$PYVENV_VIEW" \
			\
			"${__COLOR[BOLD]}" "$(
				if (( $RETVAL == 0 )); then
					printf '%b' "${__COLOR[GREEN]}"
				else
					printf '%b' "${__COLOR[RED]}"
				fi
			)" "$(
				if (( $RETVAL == 0 )); then echo '✓'; else echo '✗'; fi
			)" "$(
				if (( $RETVAL != 0 )); then printf '%d' "$RETVAL"; fi
			)" "${__COLOR[RESET]}" \
			\
			"${__PERMISSION[COLOR]}" "$USER" "${__COLOR[RESET]}" \
			"${__COLOR[YELLOW]}" "$LOCAL_HOSTNAME" "${__COLOR[RESET]}"
	)

	local result; result=$(
		printf '%b%b%s%b%b' "$PS1_PRE" \
			"${__COLOR[BLUE]}" "$PWD_VIEW" "${__COLOR[RESET]}" "$REMOTE_VIEW"
	)

	local ps1_plain; ps1_plain=${result//$__COLOR_PATTERN/}

	if (( ${#ps1_plain} > $COLUMNS )); then
		local MIN=16

		local pwd_chars_count; pwd_chars_count=$((
			${#ps1_plain} - $COLUMNS + 1
		))

		local PWD_VIEW_PLAIN; PWD_VIEW_PLAIN=${PWD_VIEW//$__COLOR_PATTERN/}
		local DIFF; DIFF=$(( ${#PWD_VIEW_PLAIN} - $pwd_chars_count ))

		if (( $DIFF < $MIN )); then
			pwd_chars_count=$(( $pwd_chars_count + ($DIFF - $MIN) ))
		fi

		local SHRINKED_PWD_VIEW; SHRINKED_PWD_VIEW=$(
			if (( ${#PWD_VIEW_PLAIN} > $MIN )); then printf '…'; fi
			printf '%s' "${PWD_VIEW:$pwd_chars_count}"
		)

		result=$(
			printf '%b%b%s%b%b' "$PS1_PRE" \
				"${__COLOR[BLUE]}" "$SHRINKED_PWD_VIEW" "${__COLOR[RESET]}" \
				"$REMOTE_VIEW"
		)

		ps1_plain=${result//$__COLOR_PATTERN/}
	fi

	local till_eol_cols; till_eol_cols=$(( $COLUMNS - ${#ps1_plain} - 1 ))
	if (( $till_eol_cols < 0 )); then till_eol_cols=0; fi

	# Exported variable
	PS1=$(
		printf '%b' "${__COLOR[RESET]}" "$ABOUT_FINAL_NEWLINE" "$result"
		if (( $till_eol_cols > 0 )); then
			printf ' '
			IFS=
			eval $(echo printf '"─%.0s"' {1..$till_eol_cols})
		fi
		printf '\n%s ' "${__PERMISSION[MARK]}"
	)

	if [[ -n $VTE_VERSION && -z $VIMRUNTIME ]]; then
		__custom_vte_prompt_command
	fi
}

# set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command

# set new b/w prompt (will be overwritten in 'prompt_command' later)
PS1=$(
	printf '%b\\u%b@%b%s%b:%b\\w%b\n%b ' \
		"${__PERMISSION[COLOR]}" "${__COLOR[RESET]}" \
		"${__COLOR[YELLOW]}" "$LOCAL_HOSTNAME" "${__COLOR[RESET]}" \
		"${__COLOR[BLUE]}" "${__COLOR[RESET]}" \
		"${__PERMISSION[MARK]}"
)


# this is for delete words by ^W
if tty -s; then stty werase ^- 2>/dev/null; fi

bind 'set show-all-if-ambiguous on'
bind '"\C-n":menu-complete'
bind '"\C-p":menu-complete-backward'

# see .bash_aliases for "burp" command
_burp_completion() {
	COMPREPLY=($(compgen -A function -abck -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -o default -F _burp_completion burp

if [[ -f ~/.bash_aliases ]]; then . ~/.bash_aliases; fi

# vim: set noet cc=81 tw=80 :

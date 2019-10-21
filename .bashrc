#!/usr/bin/env bash
# .bashrc

# if isn't running interactively, don't do anything
[[ -z $PS1 ]] && return

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

[[ -z $__TERM_NAME_PREFIX ]] && [[ $TERM == xterm-termite ]] &&
	export __TERM_NAME_PREFIX='termite | '

if [[ -n $VTE_VERSION ]]; then
	if [[ -z $VIMRUNTIME ]]; then
		. '/usr/local/etc/profile.d/vte.sh' 2>/dev/null ||
			. '/etc/profile.d/vte.sh' 2>/dev/null

		if (( $? != 0 )); then
			echo '[ERROR] vte.sh not found!' >&2
			__vte_prompt_command() { return 1; }
		fi

		__custom_vte_prompt_command() {
			local prompt=$(__vte_prompt_command 2>/dev/null)

			if (( $? == 0 )); then
				local cmd=$([[ -n $1 ]] && printf '%s | ' "$1")
				printf '%s' "${prompt/0;/0;${__TERM_NAME_PREFIX}${cmd}}"
			fi
		}
	fi

	export TERM=screen-256color

elif [[ -n $KONSOLE_VERSION ]]; then
	export TERM=screen-256color
fi

export EDITOR=$(
	# better to predefine it a file to reduce startup time
	(cat ~/.editor 2>/dev/null                      ||
	([[ -x `which nvim 2>/dev/null` ]] && echo nvim ||
	([[ -x `which vim  2>/dev/null` ]] && echo vim  ||
	([[ -x `which vi   2>/dev/null` ]] && echo vi   ||
	([[ -x `which nano 2>/dev/null` ]] && echo nano )))))
)

# don't put duplicate lines in the history
export HISTCONTROL=ignoreboth:erasedups

# set history length
HISTFILESIZE=1000000000
HISTSIZE=1000000

# append to the history file, don't overwrite it
shopt -s histappend
# check the window size after each command and,
# if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize
# correct minor errors in the spelling of a directory component in a cd command
shopt -s cdspell
# save all lines of a multiple-line command in the same history entry
# (allows easy re-editing of multi-line commands).
shopt -s cmdhist
# cd to a directory by typing its name
shopt -s autocd
# regex-style pattern matching
shopt -s extglob
# show command from history before execute it
shopt -s histverify

LOCAL_HOSTNAME=$(
	[[ -f ~/.hostname ]] && cat ~/.hostname || printf '%s' "$HOSTNAME"
)


# changing dir at bash session start for tmux new panes/windows
if [[ -n $TMUX ]]; then
	__tmux_cd=$(tmux showenv _TMUX_CD 2>/dev/null)
	if (( $? == 0 )) && [[ -n $__tmux_cd ]]; then
		__tmux_cd=${__tmux_cd#_TMUX_CD=}
		(( $? == 0 )) && [[ -n $__tmux_cd ]] && [[ -d $__tmux_cd ]] &&
			cd -- "$__tmux_cd"
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
	[[ $PWD =~ $pattern ]] || continue
	__pwd_inode=$(stat -c %i -- "$PWD")

	__to_cd=$({
		TAIL=${PWD:${#BASH_REMATCH[0]}}
		MNT_NAME=${BASH_REMATCH[1]}
		[[ -n $TAIL ]] && TAIL=/$TAIL

		NEW_WD=$(
			[[ $PWD =~ $__docker_dev_pattern ]] &&
			printf '%s%s' "$HOME" "$TAIL" ||
			printf '%s/%s%s' "$HOME" "$MNT_NAME" "$TAIL"
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
		[[ -z $WD_TAIL ]] && return 0

		IFS='/' read -r -a WD_TAIL_A <<< "$WD_TAIL"
		WD_TAIL_A=(${WD_TAIL_A[@]:1})

		WD_SLICED=${HOME}$(printf '/%s' "${WD_TAIL_A[@]}")
		[[ $WD_SLICED == ${HOME}/ ]] && WD_SLICED=$HOME

		[[ -z $__pwd_inode ]] && __pwd_inode=$(stat -c %i -- "$PWD")

		if [[ ! -d $WD_SLICED ]] ||
		(( $__pwd_inode != $(stat -c %i -- "$WD_SLICED") )); then
			return 0
		fi

		printf '%s' "$WD_SLICED"
	})

	[[ -n $__to_cd ]] && cd -- "$__to_cd"
fi

unset __docker_dev_pattern __relative_path_patterns __pwd_inode __to_cd


[[ -n $VTE_VERSION && -z $VIMRUNTIME ]] &&
	trap '__custom_vte_prompt_command "${BASH_COMMAND%% *}"' DEBUG

declare -A __PERMISSION
__PERMISSION[COLOR]=$(
	(( $UID == 0 )) &&
		printf '%b' "${__COLOR[RED]}" ||
		printf '%b' "${__COLOR[GREEN]}"
)
__PERMISSION[MARK]=$(
	printf '%b%s%b' "${__PERMISSION[COLOR]}" "$(
		(( $UID == 0 )) && echo 'α' || echo 'λ'
	)" "${__COLOR[RESET]}"
)

prompt_command() {
	local RETVAL=$?

	local PWD_VIEW=$(
		[[ $PWD =~ ^$HOME ]] &&
		printf '~%s' "${PWD#$HOME}" ||
		printf  '%s' "$PWD"
	)

	# Detecting remote mount point
	local REMOTE_VIEW=$({
		DF=$(df -l -T -- "$PWD" 2>/dev/null)
		if (( $? == 1 )); then # works on gnu/linux
			:
		else
			# works on freebsd
			REG=$'^[^\n]+\n'"[^ ]+[ ]+fusefs(\.|[ ]+)"
			[[ $DF =~ $REG ]] || return 0
		fi
		printf ' (%bremote%b)' "${__COLOR[RED]}" "${__COLOR[RESET]}"
	})

	local NIX_SHELL_VIEW=$(
		[[ -n $IN_NIX_SHELL ]] &&
			printf '(%bnix-shell%b) ' "${__COLOR[BLUE]}" "${__COLOR[RESET]}"
	)

	local PYVENV_VIEW=$(
		[[ -n $VIRTUAL_ENV ]] && printf '(pyvenv: %b%s%b) ' \
			"${__COLOR[MAGENTA]}" "${VIRTUAL_ENV##*/}" "${__COLOR[RESET]}"
	)

	local CURRENT_HISTORY_ITEM=$(history 1)

	local ABOUT_FINAL_NEWLINE=$(
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

	local PS1_PRE=$(
		printf '%s%s%b%b%s%s%b %b%s%b@%b%s%b:' \
			"$NIX_SHELL_VIEW" \
			"$PYVENV_VIEW" \
			\
			"${__COLOR[BOLD]}" "$(
				(( $RETVAL == 0 )) &&
					printf '%b' "${__COLOR[GREEN]}" ||
					printf '%b' "${__COLOR[RED]}"
			)" "$(
				(( $RETVAL == 0 )) && echo '✓' || echo '✗'
			)" "$(
				(( $RETVAL != 0 )) && printf '%d' "$RETVAL"
			)" "${__COLOR[RESET]}" \
			\
			"${__PERMISSION[COLOR]}" "$USER" "${__COLOR[RESET]}" \
			"${__COLOR[YELLOW]}" "$LOCAL_HOSTNAME" "${__COLOR[RESET]}"
	)

	local result=$(
		printf '%b%b%s%b%b' "$PS1_PRE" \
			"${__COLOR[BLUE]}" "$PWD_VIEW" "${__COLOR[RESET]}" "$REMOTE_VIEW"
	)

	local PS1_PLAIN=${result//$__COLOR_PATTERN/}

	if (( ${#PS1_PLAIN} > $COLUMNS )); then
		local MIN=16
		local pwd_chars_count=$(( ${#PS1_PLAIN} - $COLUMNS + 1 ))
		local PWD_VIEW_PLAIN=${PWD_VIEW//$__COLOR_PATTERN/}
		local DIFF=$(( ${#PWD_VIEW_PLAIN} - $pwd_chars_count ))

		(( $DIFF < $MIN )) &&
			local pwd_chars_count=$(( $pwd_chars_count + ($DIFF - $MIN) ))

		local SHRINKED_PWD_VIEW=$(
			(( ${#PWD_VIEW_PLAIN} > $MIN )) && printf '…'
			printf '%s' "${PWD_VIEW:$pwd_chars_count}"
		)

		local result=$(
			printf '%b%b%s%b%b' "$PS1_PRE" \
				"${__COLOR[BLUE]}" "$SHRINKED_PWD_VIEW" "${__COLOR[RESET]}" \
				"$REMOTE_VIEW"
		)

		local PS1_PLAIN=${result//$__COLOR_PATTERN/}
	fi

	till_eol_cols=$(( $COLUMNS - ${#PS1_PLAIN} - 1 ))
	(( $till_eol_cols < 0 )) && till_eol_cols=0

	PS1=$(
		printf '%b' "${__COLOR[RESET]}" "$ABOUT_FINAL_NEWLINE" "$result"
		(( $till_eol_cols > 0 )) && printf ' ' &&
			eval $(echo printf '"─%.0s"' {1..$till_eol_cols})
		printf '\n%s ' "${__PERMISSION[MARK]}"
	)

	[[ -n $VTE_VERSION && -z $VIMRUNTIME ]] && __custom_vte_prompt_command
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
tty -s && stty werase ^- 2>/dev/null

bind 'set show-all-if-ambiguous on'
bind '"\C-n":menu-complete'
bind '"\C-p":menu-complete-backward'

# see .bash_aliases for "burp" command
_burp_completion() {
	COMPREPLY=($(compgen -A function -abck -- "${COMP_WORDS[COMP_CWORD]}"))
}
complete -o default -F _burp_completion burp

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

# vim: set noet cc=81 tw=80 :

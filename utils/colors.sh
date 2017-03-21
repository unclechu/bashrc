#!/usr/bin/env bash

# setup color variables
color_is_on=
color_red=
color_green=
color_yellow=
color_blue=
color_white=
color_gray=
color_off=
color_user=
if [[ `which tput` != '' ]] \
&& [[ -x `which tput` ]] \
&& tput setaf 1 1>/dev/null 2>/dev/null; then
	color_is_on=true
	color_red="\[$(tput setaf 1)\]"
	color_green="\[$(tput setaf 2)\]"
	color_yellow="\[$(tput setaf 3)\]"
	color_blue="\[$(tput setaf 6)\]"
	color_white="\[$(tput setaf 7)\]"
	color_gray="\[$(tput setaf 8)\]"
	color_purple="\[$(tput setaf 5)\]"
	color_off="\[$(tput sgr0)\]"

	# set user color
	case "`id -u`" in
		0) color_user=$color_red   ;;
		*) color_user=$color_green ;;
	esac
fi

_tput() {
	if [[ $color_is_on == true ]]; then
		tput "$@"
		return $?
	fi
}

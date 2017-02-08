#!/bin/bash

# chdir from absolute path to relative
function cwd-abs-to-rel {

	local wd=`pwd`

	local reg1="^/run/media/`whoami`/\([A-Za-z_-]\+\)/home/`whoami`/"
	local reg2="^/media/`whoami`/\([A-Za-z_-]\+\)/home/`whoami`/"
	local reg3="^/media/\([A-Za-z_-]\+\)/home/`whoami`/"

	if echo "$wd" | grep "$reg1" 1>/dev/null 2>/dev/null \
	|| echo "$wd" | grep "$reg2" 1>/dev/null 2>/dev/null \
	|| echo "$wd" | grep "$reg3" 1>/dev/null 2>/dev/null; then
		local sed_search=
		if echo "$wd" | grep "$reg1" 1>/dev/null 2>/dev/null; then
			sed_search="$reg1"
		elif echo "$wd" | grep "$reg2" 1>/dev/null 2>/dev/null; then
			sed_search="$reg2"
		elif echo "$wd" | grep "$reg3" 1>/dev/null 2>/dev/null; then
			sed_search="$reg3"
		fi
		sed_search=$(echo "$sed_search" | sed -e 's/\//\\\//g')
		local mount_point_name=$(echo "$wd" | sed -e "s/$sed_search.*$/\1/")
		local abs_tail=$(echo "$wd" | sed -e "s/$sed_search//")
		local new_cwd="$HOME/$mount_point_name/$abs_tail/"
		if [ -d "$new_cwd" ]; then
			if [ -d "$HOME/$abs_tail/" ]; then
				cd "$HOME/$abs_tail/"
			else
				cd "$new_cwd"
			fi
		fi
	else
		local wdtail=${wd:$[${#HOME}+1]}
		if [ ${#wdtail} -eq 0 ]; then
			return 0
		fi
		local wdsliced=$HOME/${wdtail#*/}
		if [ ! -d "$wdsliced" ]; then
			return 0
		fi
		local wdinode=$[$(stat -c '%i' "$wd")]
		local wdslicedinode=$[$(stat -c '%i' "$wdsliced")]
		if [ $wdinode -eq $wdslicedinode ]; then
			cd "$wdsliced"
		fi
	fi
}

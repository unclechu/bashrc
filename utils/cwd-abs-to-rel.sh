#!/usr/bin/env bash

# chdir from absolute path to relative
function cwd-abs-to-rel {
	local wd=
	wd=$("$(dirname -- "${BASH_SOURCE[0]}")/cwd-abs-to-rel.pl")
	(( $? == 0 )) && cd -- "$wd"
}

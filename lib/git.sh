#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#               Do not run this script directly!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Author: Norbert Kiszka and others
# License: GPL v2

# Clone a git repository
git_clone()
{
	git clone --recurse-submodules $@
}

# Alias of a git_clone
clone()
{
	git_clone $@
}

# Pull changes from a git repository
git_pull()
{
	git pull --recurse-submodules $@
}

# Alias of a git_clone
pull()
{
	git_pull $@
}

# Usage: git_last_commit_hash_short [optional repo path]
git_last_commit_hash_short()
{
	local ret
	local dir=`echo -n $1`
	if [ "$dir" != "" ] ; then
		[ -d "$dir" ] || error "${FUNCNAME}: directory \"$dir\" doesnt exists"
		cd "$dir"
	fi
	ret=$(git log --pretty=format:'%h' -n 1 2> /dev/null) || true
	[ "$dir" == "" ] || cd - > /dev/null
	echo "$ret"
}

# Usage: git_list_modified_files [optional repo path]
git_list_modified_files()
{
	local ret
	local dir=`echo -n $1`
	if [ "$dir" != "" ] ; then
		[ -d "$dir" ] || error "${FUNCNAME}: directory \"$dir\" doesnt exists"
		cd "$dir"
	fi
	ret=$(git diff-index --name-only HEAD 2> /dev/null || true)
	[ "$dir" == "" ] || cd - > /dev/null
	echo "$ret"
}

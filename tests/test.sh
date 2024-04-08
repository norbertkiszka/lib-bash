#!/bin/bash

# Author: Norbert Kiszka
# License: GPL v2

set -e

echo "--------- $(basename ${BASH_SOURCE}) ---------"

source $(dirname $0)/../lib-bash.sh

before()
{
	echo "func: ${FUNCNAME}"
}

after()
{
	echo "func: ${FUNCNAME}"
}

at_ok()
{
	echo "func: ${FUNCNAME}"
}

at_error()
{
	echo "func: ${FUNCNAME}"
}

trap_exit_at_first before
trap_exit_at_end after
trap_exit_at_ok at_ok
trap_exit_at_error at_error

info info
notice notice
warning warning

testfail()
{
	# info without args will trigger error 
	#info
	
	# Tried to add unexist function will trigger error
	trap_exit_at_first oopsie
}

[ ! ${#BASH_SOURCE[@]} -eq 1 ] || testfail

echo "--------- $(basename ${BASH_SOURCE}) end ---------"

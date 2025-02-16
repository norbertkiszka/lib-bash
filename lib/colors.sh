#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#               Do not run this script directly!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Author: Norbert Kiszka and others
# License: GPL v2

__PRINT_DATETIME=1

__colors_GREEN="\\033[1;32m"
__colors_RED="\\033[1;31m"
__colors_YELLOW="\\033[1;33m"
__colors_WHITE="\\033[0;39m"
__colors_DEFAULT="\\033[0m"

__echo_prefix()
{
	if [ "$__PRINT_DATETIME" == "1" ] ; then
		echo -n "" `date "+%D %T"`
	fi
	echo -n " "
}

echo_()
{
	__echo_prefix
	echo ${@}
}

echo_green()
{
	__echo_prefix
	echo -en "${__colors_GREEN}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

# echo with -e
echo_green_e()
{
	__echo_prefix
	echo -e "${__colors_GREEN}${@}${__colors_DEFAULT}"
}

echo_red()
{
	__echo_prefix
	echo -en "${__colors_RED}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_red_e()
{
	__echo_prefix
	echo -e "${__colors_RED}${@}${__colors_DEFAULT}"
}

echo_yellow()
{
	__echo_prefix
	echo -en "${__colors_YELLOW}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_yellow_e()
{
	__echo_prefix
	echo -e "${__colors_YELLOW}${@}${__colors_DEFAULT}"
}

echo_white()
{
	__echo_prefix
	echo -en "${__colors_WHITE}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_white_e()
{
	__echo_prefix
	echo -e "${__colors_WHITE}${@}${__colors_DEFAULT}"
}

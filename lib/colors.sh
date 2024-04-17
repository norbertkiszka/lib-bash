#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#               Do not run this script directly!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Author: Norbert Kiszka and others
# License: GPL v2

__colors_GREEN="\\033[1;32m"
__colors_RED="\\033[1;31m"
__colors_YELLOW="\\033[1;33m"
__colors_WHITE="\\033[0;39m"
__colors_DEFAULT="\\033[0m"

# normal echo
echo_green()
{
	echo -en "${__colors_GREEN}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

# echo with -e
echo_green_e()
{
	echo -e "${__colors_GREEN}${@}${__colors_DEFAULT}"
}

echo_red()
{
	echo -en "${__colors_RED}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_red_e()
{
	echo -e "${__colors_RED}${@}${__colors_DEFAULT}"
}

echo_yellow()
{
	echo -en "${__colors_YELLOW}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_yellow_e()
{
	echo -e "${__colors_YELLOW}${@}${__colors_DEFAULT}"
}

echo_white()
{
	echo -en "${__colors_WHITE}"
	echo -n "${@}"
	echo -e "${__colors_DEFAULT}"
}

echo_white_e()
{
	echo -e "${__colors_WHITE}${@}${__colors_DEFAULT}"
}

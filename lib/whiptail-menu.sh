#!/bin/bash

# Author: Norbert Kiszka and others
# License: GPL v2

# Remove all previously added options and settings.
whiptail_menu_reset()
{
	unset __WHIPTAIL_MENU_OPTIONS # used to give it for whiptail
	unset __WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING
	unset __WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY
	unset __WHIPTAIL_MENU_HEIGHT
	unset __WHIPTAIL_MENU_WIDTH
	unset __WHIPTAIL_MENU_LIST_HEIGHT
	declare -A __WHIPTAIL_MENU_OPTIONS
	declare -A __WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING
	__WHIPTAIL_MENU_HEIGHT=25
	__WHIPTAIL_MENU_WIDTH=110
	__WHIPTAIL_MENU_LIST_HEIGHT=15
}

whiptail_menu_set_height()
{
	__WHIPTAIL_MENU_HEIGHT="${1}"
}

whiptail_menu_set_width()
{
	__WHIPTAIL_MENU_WIDTH="${1}"
}

whiptail_menu_set_list_height()
{
	__WHIPTAIL_MENU_LIST_HEIGHT="${1}"
}

whiptail_menu_set_dimensions()
{
	__WHIPTAIL_MENU_HEIGHT="${1}"
	__WHIPTAIL_MENU_WIDTH="${2}"
	__WHIPTAIL_MENU_LIST_HEIGHT="${3}"
}

# This option is being reset after every whiptail_menu_execute call.
# When not called, dot is being removed from output var 
whiptail_menu_dont_add_dot_in_key()
{
	__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY="y"
}

# This option is NOT being reset after whiptail_menu_execute call.
whiptail_menu_title_set_prefix()
{
	__WHIPTAIL_MENU_TITLE_PREFIX="${*}"
}

# Add one option.
# Usage: whiptail_menu_options_add key name
whiptail_menu_options_add()
{
	__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING["${1}"]=${2}
	local KEY="${1}"
	[ "${__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY}" != "" ] || KEY+="."
	__WHIPTAIL_MENU_OPTIONS+=("$KEY" "   ${2}")
}

# Arg1: menu name (optional).
# Arg2: Menu text (optional).
# Arg3: optional height (default is 25).
# Arg4: optional width (default is 110)
# Arg5: optional list-height (default is 15)
# Output is two variables: WHIPTAIL_MENU_OPTION_ID and WHIPTAIL_MENU_OPTION_NAME
whiptail_menu_execute()
{
	info "Executing menu: \"${1}\""
	[ ${#__WHIPTAIL_MENU_OPTIONS[@]} -gt 0 ] || error "${FUNCNAME}: no options added via whiptail_menu_options_add"

	WHIPTAIL_MENU_OPTION_ID=$(echo -n `whiptail --title "${__WHIPTAIL_MENU_TITLE_PREFIX}${1}" --menu "${2}" --cancel-button Exit --ok-button Select ${__WHIPTAIL_MENU_HEIGHT} ${__WHIPTAIL_MENU_WIDTH} ${__WHIPTAIL_MENU_LIST_HEIGHT} "${__WHIPTAIL_MENU_OPTIONS[@]}" 3>&1 1>&2 2>&3`)
	[ "${__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY}" != "" ] || WHIPTAIL_MENU_OPTION_ID=$(echo "$WHIPTAIL_MENU_OPTION_ID" | sed 's/.\{1\}$//')
	WHIPTAIL_MENU_OPTION_NAME="${__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[$WHIPTAIL_MENU_OPTION_ID]}"
	if [ "${WHIPTAIL_MENU_OPTION_ID}" == "" ] ; then
		notice "User exit from menu: ${1}"
		whiptail_menu_reset
		exit 0
	else
		info "Selected menu option: ${WHIPTAIL_MENU_OPTION_ID} ${WHIPTAIL_MENU_OPTION_NAME}"
	fi
	whiptail_menu_reset
}

__whiptail_menu_checks_at_exit()
{
	[ ${#__WHIPTAIL_MENU_OPTIONS[@]} -lt 1 ] || warning "${FUNCNAME}: option(s) added but menu was not executed"
}

trap_exit_at_end __whiptail_menu_checks_at_exit

whiptail_menu_reset
unset __WHIPTAIL_MENU_TITLE_PREFIX
__WHIPTAIL_MENU_TITLE_PREFIX=""
WHIPTAIL_MENU_OPTION_ID=
WHIPTAIL_MENU_OPTION_NAME=


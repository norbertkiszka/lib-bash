#!/bin/bash

# Author: Norbert Kiszka and others
# License: GPL v2

__WHIPTAIL_MENU_DEFAULT_HEIGHT=25
__WHIPTAIL_MENU_DEFAULT_WIDTH=110
__WHIPTAIL_MENU_DEFAULT_LIST_HEIGHT=15
__WHIPTAIL_MENU_DEFAULT_BACKTITLE=""

# Remove all previously added options and settings.
whiptail_menu_reset()
{
	__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY=""
	__WHIPTAIL_MENU_DEFAULT_ITEM=""
	__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING=()
	__WHIPTAIL_MENU_OPTIONS_ORDER=()
	__WHIPTAIL_MENU_HEIGHT=$__WHIPTAIL_MENU_DEFAULT_HEIGHT
	__WHIPTAIL_MENU_WIDTH=$__WHIPTAIL_MENU_DEFAULT_WIDTH
	__WHIPTAIL_MENU_LIST_HEIGHT=$__WHIPTAIL_MENU_DEFAULT_LIST_HEIGHT
	__WHIPTAIL_MENU_BACKTITLE="$__WHIPTAIL_MENU_DEFAULT_BACKTITLE"
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
	[ "${1}" == ""  ] || __WHIPTAIL_MENU_HEIGHT="${1}"
	[ "${2}" == ""  ] || __WHIPTAIL_MENU_WIDTH="${2}"
	[ "${3}" == ""  ] || __WHIPTAIL_MENU_LIST_HEIGHT="${3}"
}

whiptail_menu_set_default_height()
{
	__WHIPTAIL_MENU_DEFAULT_HEIGHT="${1}"
}

whiptail_menu_set_default_width()
{
	__WHIPTAIL_MENU_DEFAULT_WIDTH="${1}"
}

whiptail_menu_set_default_list_height()
{
	__WHIPTAIL_MENU_DEFAULT_LIST_HEIGHT="${1}"
}

whiptail_menu_set_default_dimensions()
{
	[ "${1}" == ""  ] || __WHIPTAIL_MENU_DEFAULT_HEIGHT="${1}"
	[ "${2}" == ""  ] || __WHIPTAIL_MENU_DEFAULT_WIDTH="${2}"
	[ "${3}" == ""  ] || __WHIPTAIL_MENU_DEFAULT_LIST_HEIGHT="${3}"
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
	__WHIPTAIL_MENU_TITLE_PREFIX="${@}"
}

whiptail_menu_set_backtitle()
{
	__WHIPTAIL_MENU_BACKTITLE="${@}"
}

whiptail_menu_set_default_backtitle()
{
	__WHIPTAIL_MENU_DEFAULT_BACKTITLE="${@}"
	[ "$__WHIPTAIL_MENU_BACKTITLE" == "" ] && __WHIPTAIL_MENU_BACKTITLE="${@}"
}

whiptail_menu_is_option_id_exist()
{
	[ "${__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[$1]+isset}" ] && return 0
	return 1
}

whiptail_menu_set_default_item()
{
	local required_item="${@}"
	
	if ! whiptail_menu_is_option_id_exist "${required_item}" ; then
		warning "${FUNCNAME}: there is no added menu item with id \"${required_item}\" (yet)..."
	fi
	__WHIPTAIL_MENU_DEFAULT_ITEM="${required_item}"
}

whiptail_menu_set_default_item_force()
{
	__WHIPTAIL_MENU_DEFAULT_ITEM="${@}"
}

# Add one option.
# Usage: whiptail_menu_option_add key name
# Usage: whiptail_menu_option_add "" name
whiptail_menu_option_add()
{
	local key="$1"
	
	if [ "$key" == "" ] ; then
		if [ "${#__WHIPTAIL_MENU_OPTIONS_ORDER[@]}" -lt 1 ] ; then
			key=1
		else
			((key=__WHIPTAIL_MENU_OPTIONS_ORDER[-1]+1))
		fi
	fi
	
	__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING["${key}"]="${2}"
	__WHIPTAIL_MENU_OPTIONS_ORDER+=("$key")
}

# alias of whiptail_menu_option_add
whiptail_menu_add_option()
{
	whiptail_menu_option_add $@
}

# alias of whiptail_menu_option_add
# In versions before 0.2.0 it was a typo - hence this alias
whiptail_menu_options_add()
{
	whiptail_menu_option_add $@
}

whiptail_menu_count_options()
{
	echo ${#__WHIPTAIL_MENU_OPTIONS_ORDER[@]}
}

# alias of whiptail_menu_count_options
whiptail_menu_options_count()
{
	whiptail_menu_count_options
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
	[ ${#__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[@]} -gt 0 ] || error "${FUNCNAME}: no options added via whiptail_menu_option_add"
	
	local value=""
	local -a args
	local -a options
	local min_width
	
	local title="${__WHIPTAIL_MENU_TITLE_PREFIX}${1}"
	
	[ "$3" == "" ] || __WHIPTAIL_MENU_HEIGHT=$3
	[ "$4" == "" ] || __WHIPTAIL_MENU_WIDTH=$4
	[ "$5" == "" ] || __WHIPTAIL_MENU_LIST_HEIGHT=$5
	
	[ "${title}" == "" ] || args+=("--title=$title")
	[ "${__WHIPTAIL_MENU_BACKTITLE}" == "" ] || args+=("--backtitle=$__WHIPTAIL_MENU_BACKTITLE")
	
	[ "${__WHIPTAIL_MENU_DEFAULT_ITEM}" != "" ] && [ "$__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY" == "" ] && args+=("--default-item=${__WHIPTAIL_MENU_DEFAULT_ITEM}.")
	[ "${__WHIPTAIL_MENU_DEFAULT_ITEM}" != "" ] && [ "$__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY" != "" ] && args+=("--default-item=${__WHIPTAIL_MENU_DEFAULT_ITEM}")
	
	if [ "${__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY}" == "" ] ; then
		for key in "${__WHIPTAIL_MENU_OPTIONS_ORDER[@]}"
		do
			value="${__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[$key]}"
			[ "$value" == "" ] || value="   $value"
			options+=("${key}." "   ${value}")
		done
	else
		for key in "${__WHIPTAIL_MENU_OPTIONS_ORDER[@]}"
		do
			value="${__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[$key]}"
			[ "$value" == "" ] || value="   $value"
			options+=("${key}" "   ${value}")
		done
	fi
	
	min_width=$((${#title}+6))
	[ "$__WHIPTAIL_MENU_WIDTH" -ge $min_width ] || __WHIPTAIL_MENU_WIDTH=$min_width
	
	set +e
	WHIPTAIL_MENU_OPTION_ID=$(whiptail "${args[@]}" --menu "${2}" --cancel-button Exit --ok-button Select ${__WHIPTAIL_MENU_HEIGHT} ${__WHIPTAIL_MENU_WIDTH} ${__WHIPTAIL_MENU_LIST_HEIGHT} \
"${options[@]}" 3>&1 1>&2 2>&3)
	__whiptail_exit_status=$?
	set -e
	
	if [ $__whiptail_exit_status == 1 ] || [ $__whiptail_exit_status == 255 ] ; then
		notice "Exit from menu: ${1}"
		[ $__whiptail_exit_status == 1 ] && info "whiptail menu exit via button"
		[ $__whiptail_exit_status == 255 ] && notice "whiptail menu exit via ESC key or whiptail error occured"
		whiptail_menu_reset # avoid warning generated in __whiptail_menu_checks_at_exit() due to "not executed options"
		exit 0
	elif [ $__whiptail_exit_status != 0 ] ; then
		error "whiptail returned with unknown error status"
	fi
	
	[ "${__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY}" != "" ] || WHIPTAIL_MENU_OPTION_ID=$(echo "$WHIPTAIL_MENU_OPTION_ID" | sed 's/.\{1\}$//')
	WHIPTAIL_MENU_OPTION_NAME="${__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[$WHIPTAIL_MENU_OPTION_ID]}"
	info "Selected menu option: ${WHIPTAIL_MENU_OPTION_ID} ${WHIPTAIL_MENU_OPTION_NAME}"
	whiptail_menu_reset
}

__whiptail_menu_checks_at_exit()
{
	[ ${#__WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING[@]} -lt 1 ] || warning "${FUNCNAME}: option(s) added but menu was not executed"
}

trap_exit_at_end __whiptail_menu_checks_at_exit

whiptail_menu_reset
unset __WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING
declare -A __WHIPTAIL_MENU_OPTIONS_KEY_TO_STRING
unset __WHIPTAIL_MENU_TITLE_PREFIX
__WHIPTAIL_MENU_TITLE_PREFIX=""
__WHIPTAIL_MENU_BACKTITLE=""
WHIPTAIL_MENU_OPTION_ID=
WHIPTAIL_MENU_OPTION_NAME=
declare -a __WHIPTAIL_MENU_OPTIONS_ORDER
__WHIPTAIL_MENU_DONT_ADD_DOT_IN_KEY=""
__WHIPTAIL_MENU_DEFAULT_ITEM=""

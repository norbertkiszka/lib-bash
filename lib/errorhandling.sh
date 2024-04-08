#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#               Do not run this script directly!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Author: Norbert Kiszka and others
# License: GPL v2

show_stacktrace_for_warnings()
{
	__SHOW_STACKTRACE_FOR_WARNINGS="y"
}

# Normally stacktrace is show only on exit with error code
always_show_stacktrace_at_exit()
{
	__ALWAYS_SHOW_STACKTRACE_AT_EXIT="y"
}

# call error (exit 1) at warning
# NOTE: this will not work when exit was trapped by __on_exit()
forbidden_warning()
{
	__FORBIDDEN_WARNING="y"
}

# Will do error if function is called with no args or empty text or white spaces in arg(s).
# You have to pass $* to first arg of this function - everytime.
check_require_args_with_real_data()
{
	local teststring="$(echo -n ${1})" # trim whitespaces
	[ "${1}" != "" ] || error "${FUNCNAME[1]}() called with empty text from ${BASH_SOURCE[2]}:${BASH_LINENO[1]}"
}

is_executable()
{
	type "${*}" &> /dev/null && return 0 || return 1
}

require_executable()
{
	is_executable "${*}" || error "${FUNCNAME[1]}() requies arg to be executable, but ${*} doesnt look like a executable"
}

# info with normal echo
info()
{
	check_require_args_with_real_data "${*}"
	local text=" INFO: ${*}"
	echo_green "${text}"
}

# info with echo -e
info_e()
{
	info "$(echo -en "${*}")"
}

notice()
{
	check_require_args_with_real_data "${*}"
	local text=" NOTICE: ${*}"
	echo_yellow "${text}"
}

notice_e()
{
	notice "$(echo -en "${*}")"
}

warning()
{
	check_require_args_with_real_data "${*}"
	local text="${*}"
	echo_red " WARNING: ${text}"
	if [ "$__SHOW_STACKTRACE_FOR_WARNINGS" != "" ] \
	|| [ "$__INSIDE_OF_ON_EXIT" != "" ] \
	&& [ "${__FORBIDDEN_WARNING}" == "" ] ; then # dont display stacktrace two times (__FORBIDDEN_WARNING will trigger error couple lines later)
		echo_red "$(scriptstacktrace)"
	fi
	[ "${__FORBIDDEN_WARNING}" == "" ] || error "Forbidden warning"
	# error() not always call exit
	# whiptail inside __on_exit is no no
	# dont display whiptail two times for same problem - this will also make same behaviour every time
	if [ "$__ERRORHANDLING_USE_WHIPTAIL_FOR_WARNING" != "" ] \
	&& [ "$__INSIDE_OF_ON_EXIT" == "" ] \
	&& [ "$__FORBIDDEN_WARNING" == "" ] ; then
		whiptail_display_warning "${*}"
	fi
}

warning_e()
{
	warning "$(echo -en "${*}")"
}

error_without_exit()
{
	check_require_args_with_real_data "${*}"
	local text=" ERROR: ${*}"
	echo_red "${text}"
	[ "$__ERRORHANDLING_USE_WHIPTAIL_FOR_ERROR" == "" ] || whiptail_display_error "${*}"
	if [ "${__INSIDE_OF_ON_EXIT}" != "" ] && [ "${__INTERNAL_ERROR_CALL}" == "" ] ; then
		__ERROR_INSIDE_OF_ON_EXIT="y"
		notice "error triggered inside of __on_exit()"
	fi
	scriptstacktrace
}

error_without_exit_e()
{
	error_without_exit "$(echo -en "${*}")"
}

error()
{
	check_require_args_with_real_data "${*}"
	error_without_exit "${*}"
	if [ "${__lib_bash_called_directly}" == "" ] && [ "${__INSIDE_OF_ON_EXIT}" == "" ] ; then
		exit 1
	else
		return
	fi
}

error_e()
{
	error "$(echo -en "${*}")"
}

success()
{
	check_require_args_with_real_data "${*}"
	local text=" SUCCESS: ${*}"
	echo_green "${text}"
}

success_e()
{
	success "$(echo -en "${*}")"
}

success_whiptail()
{
	check_require_args_with_real_data "${*}"
	PREVIOUS_NEWT_COLORS=$NEWT_COLORS
	export NEWT_COLORS='
window=,green
border=white,green
textbox=white,green
button=black,white
'
	whiptail --title "Orange Rigol Build System" --msgbox "${*}" --ok-button "OK" 15 80 0
	NEWT_COLORS=$PREVIOUS_NEWT_COLORS
}

success_whiptail_e()
{
	success_whiptail "$(echo -en "${*}")"
}

errorhandling_use_whiptail_for_warning()
{
	if [ "$1" == "n" ] || [ "$1" == "0" ] ; then
		__ERRORHANDLING_USE_WHIPTAIL_FOR_WARNING=""
	else
		__ERRORHANDLING_USE_WHIPTAIL_FOR_WARNING="y"
	fi
}

errorhandling_use_whiptail_for_error()
{
	if [ "$1" == "n" ] || [ "$1" == "0" ] ; then
		__ERRORHANDLING_USE_WHIPTAIL_FOR_ERROR=""
	else
		__ERRORHANDLING_USE_WHIPTAIL_FOR_ERROR="y"
	fi
}

whiptail_display_warning()
{
	MESSAGE="WARNING: ${*}"
	local PREVIOUS_NEWT_COLORS=$NEWT_COLORS
	export NEWT_COLORS='
border=red,
'
	whiptail --title "[WARNING]" --msgbox "${MESSAGE}" --ok-button "Continue" --cancel-button "Exit" 20 80 0
	NEWT_COLORS=$PREVIOUS_NEWT_COLORS
}

whiptail_display_error()
{
	MESSAGE="ERROR: ${*}"
	local PREVIOUS_NEWT_COLORS=$NEWT_COLORS
	export NEWT_COLORS='
window=,red
border=white,red
textbox=white,red
button=black,white
'
	whiptail --title "[ERROR]" --msgbox "${MESSAGE}" --ok-button "Exit" 20 80 0
	NEWT_COLORS=$PREVIOUS_NEWT_COLORS
}

__on_exit()
{
	EXIT_STATUS=$?
	__INSIDE_OF_ON_EXIT="y" # dont call exit one more time
	unset __ERROR_INSIDE_OF_ON_EXIT # we will know that some error occured here or in outside function
	unset __FORBIDDEN_WARNING # forbidden forbidden
	
	if [ "${EXIT_STATUS}" != "0" ] ; then
		__INTERNAL_ERROR_CALL="y"
		error_without_exit "Script exit with error code ${EXIT_STATUS}"
		unset __INTERNAL_ERROR_CALL
	else
		info "Script exit with no error"
	fi
	
	local func_to_call=""
	
	for func_to_call in "${__TRAP_EXIT_AT_FIRST[@]}"
	do
		[ "${__ERROR_INSIDE_OF_ON_EXIT}" == "" ] || break;
		$func_to_call
	done
	
	if [ "${EXIT_STATUS}" != "0" ] || [ "${__ALWAYS_SHOW_STACKTRACE_AT_EXIT}" != "" ] ; then
		scriptstacktrace
		#sctrace
	fi
	
	if [ "${EXIT_STATUS}" != "0" ] ; then
		#error_without_exit "Script exit with error code ${EXIT_STATUS}"
		for func_to_call in "${__TRAP_EXIT_AT_ERROR[@]}"
		do
			[ "${__ERROR_INSIDE_OF_ON_EXIT}" == "" ] || break;
			$func_to_call
		done
	else
		for func_to_call in "${__TRAP_EXIT_AT_OK[@]}"
		do
			[ "${__ERROR_INSIDE_OF_ON_EXIT}" == "" ] || break;
			$func_to_call
		done
	fi
	
	for func_to_call in "${__TRAP_EXIT_AT_END[@]}"
	do
		[ "${__ERROR_INSIDE_OF_ON_EXIT}" == "" ] || break;
		$func_to_call
	done
	
	# If error occured somwhere here (called functions), then let others know, that we had a error
	if [ "${EXIT_STATUS}" == "0" ] && [ "${__ERROR_INSIDE_OF_ON_EXIT}" != "" ] ; then
		exit 1
	fi
}

__on_sigint()
{
	if [ "${__lib_bash_called_directly}" == "" ] ; then
		notice "Signal SIGINT catched (CTRL+C) -> executing exit 1"
		exit 1
	else
		__message="Signal SIGINT catched (CTRL+C)"
		if [ -e /usr/games/cowsay ] ; then
			/usr/games/cowsay "$__message"
		else
			notice "$__message"
		fi
	fi
}

# Add trap exit function at very beginning (mainly something more important)
# Arg1: function name
trap_exit_at_first()
{
	require_executable $1
	__TRAP_EXIT_AT_FIRST+=($1)
}

# Add trap exit function at very end (mainly something less important)
# Arg1: function name
trap_exit_at_end()
{
	require_executable $1
	__TRAP_EXIT_AT_END+=($1)
}

# Add trap exit function at no error (exit 0)
# Arg1: function name
trap_exit_at_ok()
{
	require_executable $1
	__TRAP_EXIT_AT_OK+=($1)
}

# Add trap exit function at error (exit 1)
# Arg1: function name
trap_exit_at_error()
{
	require_executable $1
	__TRAP_EXIT_AT_ERROR+=($1)
}

scriptstacktrace()
{
	echo " ------------------ Script stack trace -------------------"
	local output=""
	
	local key_stack=""
	local ROOT_STRLEN=$(("${#ROOT}"+1)) # strlen of build root path with ending "/"
	for key_stack in "${!BASH_SOURCE[@]}" ; do
		local FILENAME="${BASH_SOURCE[$key_stack+1]}"
		if [ "${FILENAME:0:$ROOT_STRLEN}" == "${ROOT}/" ] ; then
			FILENAME=${FILENAME:$ROOT_STRLEN}
		fi
		output+="   ${FILENAME}:${BASH_LINENO[$key_stack]}\n"
	done
	echo -en "${output}" | tac | tail -n +2
	
	echo " Function stack trace:"
	output=""
	local IS_FIRST_FUNC="y" # dont print myself
	for value_funcname in "${FUNCNAME[@]}" ; do
		[ "${IS_FIRST_FUNC}" == "y" ] || output+="   ${value_funcname}\n"
		unset IS_FIRST_FUNC
	done
	echo -en "${output}" | tac
	echo " --------------- Script stack trace end of ---------------"
}

unset __TRAP_EXIT_AT_FIRST
declare -a __TRAP_EXIT_AT_FIRST
unset __TRAP_EXIT_AT_END
declare -a __TRAP_EXIT_AT_END
unset __TRAP_EXIT_AT_OK
declare -a __TRAP_EXIT_AT_OK
unset __TRAP_EXIT_AT_ERROR
declare -a __TRAP_EXIT_AT_NO_ERROR
unset __INSIDE_OF_ON_EXIT
unset __INTERNAL_ERROR_CALL

trap __on_exit EXIT
trap __on_sigint INT

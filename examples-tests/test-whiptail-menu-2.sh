#!/bin/bash

# Author: Norbert Kiszka
# License: GPL v2

set -e

source $(dirname $0)/../lib-bash.sh


whiptail_menu_option_add "1" "Alice"
whiptail_menu_option_add "2" "Norbert"
whiptail_menu_option_add "3" "Somebody else"

whiptail_menu_execute "My name is:"

case "${WHIPTAIL_MENU_OPTION_ID}" in
	"1")
		info "My name is Alice and I remember everything."
		info "https://youtu.be/xnc3QTjSGVk?t=285"
		;;
	"2")
		info "You must be a great developer."
		;;
	"3")
		info "Hi ${WHIPTAIL_MENU_OPTION_NAME}!"
		;;
	"*")
		notice "Oopsie"
		;;
esac

#echo "whiptail_menu_execute() results:"
#echo "var OPTION_ID: ${WHIPTAIL_MENU_OPTION_ID}"
#echo "var WHIPTAIL_MENU_OPTION_NAME: ${WHIPTAIL_MENU_OPTION_NAME}"


#!/bin/bash

# Author: Norbert Kiszka
# License: GPL v2

set -e

source $(dirname $0)/../lib-bash.sh

echo "--------- whiptail menu first test ---------"

whiptail_menu_options_add "1" "Alice"
whiptail_menu_options_add "2" "has a"
whiptail_menu_options_add "3" "cat"

whiptail_menu_execute

echo "whiptail_menu_execute() results:"
echo "var OPTION_ID: ${WHIPTAIL_MENU_OPTION_ID}"
echo "var WHIPTAIL_MENU_OPTION_NAME: ${WHIPTAIL_MENU_OPTION_NAME}"

echo "--------- whiptail menu second test ---------"

whiptail_menu_title_set_prefix "Test prefix | "
whiptail_menu_dont_add_dot_in_key
whiptail_menu_set_dimensions 15 60 8

whiptail_menu_options_add "1" "but"
whiptail_menu_options_add "2" "cat"
whiptail_menu_options_add "3" "has a"
whiptail_menu_options_add "4" "hangover"

whiptail_menu_execute "test menu"

echo "whiptail_menu_execute() results:"
echo "var OPTION_ID: ${WHIPTAIL_MENU_OPTION_ID}"
echo "var WHIPTAIL_MENU_OPTION_NAME: ${WHIPTAIL_MENU_OPTION_NAME}"

echo "--------- end of script ---------"

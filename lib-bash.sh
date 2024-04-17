#!/bin/bash

# Author: Norbert Kiszka and others
# License: GPL v2

# Library primarly intented for a Orange Rigol project, which can be found at https://github.com/norbertkiszka/rigol-orangerigol-build
# Some of code is a copy from https://sourceforge.net/projects/libbash/

if [ "$__LIB_BASH_REQUIRED_MINIMAL_BASH_VERSION" != "" ] ; then
	__message="Lib-Bash: Here we go again..."
	if [ -e /usr/games/cowsay ] ; then
		/usr/games/cowsay "$__message"
	else
		echo "$__message"
	fi
	#return
fi

__lib_bash_filename="$(basename "$BASH_SOURCE")"
__lib_bash_real_filename="$(realpath "$BASH_SOURCE")"

if [ ${#BASH_SOURCE[@]} -eq 1 ] && [ "${1}" != "libignoredirect" ] ; then
	__lib_bash_called_directly="y"
	__message="${__lib_bash_filename} called directly"
	if [ -e /usr/games/cowsay ] ; then
		/usr/games/cowsay "$__message"
	else
		echo "$__message"
	fi
else
		set -e
		__lib_bash_called_directly=""
fi

if [ "${LIB_BASH_VERSION}" == "" ] ; then
	readonly LIB_BASH_VERSION="0.2.0"
	readonly __LIB_BASH_REQUIRED_MINIMAL_BASH_VERSION="4.2"
elif [ "${LIB_BASH_VERSION}" != "0.2.0" ]; then
	echo "${__lib_bash_filename} called again but now we have other version!!!"
	echo "Please restart bash if You want to load other version."
	exit 1
fi

ROOT=`pwd` # For external use. Please dont overwrite this - I cant make it readonly since this lib can be called multiple times inside same enviroment.

# Arg1: version to test
# Arg2: required version
# Borrowed from a https://unix.stackexchange.com/questions/285924/how-to-compare-a-programs-version-in-a-shell-script and changed a little bit
version_is_eqal_or_greater_than()
{
	if [ "$(printf '%s\n' "${2}" "${1}" | sort -V | head -n1)" = "${2}" ]; then 
		return 0
	else
        return 1
	fi
}

if ! version_is_eqal_or_greater_than "${BASH_VERSION}" "${__LIB_BASH_REQUIRED_MINIMAL_BASH_VERSION}" ; then
	echo "This lib requires bash version "${__LIB_BASH_REQUIRED_MINIMAL_BASH_VERSION}" or greater but ${BASH_VERSION} was detected"
	exit 1
fi

__lib_bash_build_libdir="$(dirname $BASH_SOURCE)/lib"
source ${__lib_bash_build_libdir}/colors.sh
source ${__lib_bash_build_libdir}/sctrace.sh
source ${__lib_bash_build_libdir}/errorhandling.sh
source ${__lib_bash_build_libdir}/sys.sh
source ${__lib_bash_build_libdir}/whiptail-menu.sh
source ${__lib_bash_build_libdir}/git.sh

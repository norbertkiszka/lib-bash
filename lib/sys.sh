#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#               Do not run this script directly!
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Author: Norbert Kiszka and others
# License: GPL v2

unset __SYS_TMP_DIRS
declare -a __SYS_TMP_DIRS
unset __SYS_ADDITIONAL_BINDS
declare -a __SYS_ADDITIONAL_BINDS
unset __SYS_TMP_MOUNTS
declare -a __SYS_TMP_MOUNTS

__SYS_MESSAGE_PLEASE_FIX="Please fix Your system or try to reboot it."
__SYS_MESSAGE_MISSING="is missing or this is something else than should be. ${__SYS_MESSAGE_PLEASE_FIX}"

# First arg is amount of chars generated. For ex. 3 will generate: 0f7.
# When first arg is ommited, it will generate 32 chars
random_hex()
{
	CHARS="$1"
	[ "$CHARS" != "" ] || CHARS=32
	sys_require_dev_urandom
	cat /dev/urandom | tr -cd 'a-f0-9' | head -c "$CHARS"
}

sys_mktempdir()
{
	local TEMPDIR=$(mktemp -d)
	[ "${TEMPDIR}" != "" ] || error "${FUNCNAME}: cannot happen..."
	__SYS_TMP_DIRS+=(${TEMPDIR})
	local testfile="${TEMPDIR}/test_file_sys_mktempdir_$(random_hex)"
	random_hex > testfile || error "${FUNCNAME}: cannot write into temp directory: ${TEMPDIR}"
	rm -f testfile
	echo -n "${TEMPDIR}"
}

sys_require_dev_null()
{
	local file="/dev/null"
	if [ ! -e "$file" ] || [ "$(stat -Lc %t:%T "$file")" != "1:3" ] ; then
		error "$file ${__SYS_MESSAGE_MISSING}"
	fi
}

sys_require_dev_zero()
{
	local file="/dev/zero"
	if [ ! -e "$file" ] || [ "$(stat -Lc %t:%T "$file")" != "1:5" ] ; then
		error "$file ${__SYS_MESSAGE_MISSING}"
	fi
}

sys_require_dev_urandom()
{
	local file="/dev/urandom"
	if [ ! -e "$file" ] || [ "$(stat -Lc %t:%T "$file")" != "1:9" ] ; then
		error "$file ${__SYS_MESSAGE_MISSING}"
	fi
}

sys_require_tmp()
{
	sys_require_dev_null
	sys_mktempdir > /dev/null || error "Cannot create temp directories. ${__SYS_MESSAGE_PLEASE_FIX}"
}

# Usage: sys_chroot_add_bind source_dir destination_dir
# Usage: sys_chroot_add_bind dir
# Destination dir must be relative to destination
sys_chroot_add_bind()
{
	local source=`echo -n $1`
	local destination=`echo -n $2`
	
	[ "${source}" == "" ] && error "${FUNCNAME}: bad usage"
	[ ! -d "${source}" ] && error "${FUNCNAME}: source directory \"${source}\" doesnt exist"
	
	if [ "${destination}" == "" ] ; then
		destination="${source}"
	#elif [ ! -d "${destination}" ] ; then
	#	error "${FUNCNAME}: destination directory \"${destination}\" doesnt exist"
	fi
	
	__SYS_ADDITIONAL_BINDS+=(${source})
	__SYS_ADDITIONAL_BINDS+=(${destination})
}

__sys_unset_tmp_mount()
{
	local i
	for i in ${!__SYS_TMP_MOUNTS[@]} ; do if [ "${__SYS_TMP_MOUNTS[i]}" == "$@" ] ; then unset __SYS_TMP_MOUNTS[i] ; fi ; done
}

# Usage: sys_chroot destination_path command [command arguments]
sys_chroot()
{
	local chroot_dest="$1"
	local cmd="${@:2}"
	cmd=`echo -n ${cmd}`
	local d
	local i
	local i2
	local bind_src
	local bind_dest
	
	info "Chroot $chroot_dest with cmd: $cmd"
	
	if [ "$chroot_dest" == "" ] || [ "$chroot_dest" == "/" ] ; then
		error "${FUNCNAME}: bad dest: \"${chroot_dest}\""
	fi
	
	if [ "$cmd" == "" ] ; then
		error "${FUNCNAME}: empty cmd"
	fi
	
	for d in "proc" "sys" "dev" "dev/pts"
	do
		if [ ! -d "${chroot_dest}/${d}" ] ; then
			mkdir -p "${chroot_dest}/${d}"
			chmod 755 "${chroot_dest}/${d}"
		fi
	done
	
	if [ -e "${chroot_dest}/proc/cmdline" ]; then
		error "${FUNCNAME}: /proc already mounted"
	else
		mount -t proc proc "${chroot_dest}/proc" || error "Failed to mount /proc"
		#mount --bind /proc "$chroot_dest/proc" || error "Failed to mount --bind /proc"
		__SYS_TMP_MOUNTS+=(${chroot_dest}/proc)
	fi
	
	if [ -d "${chroot_dest}/sys/kernel" ]; then
		error "${FUNCNAME}: /sys already mounted"
	else
		mount -t sysfs sys "${chroot_dest}/sys" || error "Failed to mount /sys"
		#mount --bind /sys "$chroot_dest/sys" || error "Failed to mount --bind /sys"
		__SYS_TMP_MOUNTS+=(${chroot_dest}/sys)
	fi
	
	if [ -e "${chroot_dest}/dev/mem" ]; then
		error "${FUNCNAME}: /dev already mounted"
	else
		mount -t devtmpfs devtmpfs "${chroot_dest}/dev" || error "Failed to mount /dev"
		#mount --rbind /dev "$chroot_dest/dev" || error "Failed to mount --rbind /dev"
		__SYS_TMP_MOUNTS+=(${chroot_dest}/dev)
	fi
	
	if [ -e "${chroot_dest}/dev/pts/ptmx" ]; then
		error "${FUNCNAME}: /dev/pts already mounted"
	else
		mount devpts "${chroot_dest}/dev/pts" -t devpts || error "Failed to mount /dev/pts"
		#mount --bind /dev/pts "$chroot_dest/dev/pts" || error "Failed to mount --bind /dev/pts"
		__SYS_TMP_MOUNTS+=(${chroot_dest}/dev/pts)
	fi
	
	if [ "$(expr ${#__SYS_ADDITIONAL_BINDS[@]} % 2)" == "1" ] ; then
		error "${FUNCNAME}: elements num in \$__SYS_ADDITIONAL_BINDS should be even..."
	fi
	
	for ((i=0; i<${#__SYS_ADDITIONAL_BINDS[@]}; i=i+2))
	do
		bind_src=$(readlink -m "${__SYS_ADDITIONAL_BINDS[i]}")
		bind_dest=$(readlink -m "${chroot_dest}/${__SYS_ADDITIONAL_BINDS[i+1]}")
		
		if [ "$(mount | grep "${bind_dest}")" != "" ] ; then
			error "${FUNCNAME}: ${bind_dest} already mounted"
		fi
		
		if [ ! -d "${__SYS_ADDITIONAL_BINDS[i+1]}" ] ; then
			mkdir -p "${__SYS_ADDITIONAL_BINDS[i+1]}"
			chmod 755 "${__SYS_ADDITIONAL_BINDS[i+1]}"
		fi
		
		mount --bind "$bind_src" "$bind_dest" || build_error "Failed to mount --bind \"$bind_src\" \"$bind_dest\""
		__SYS_TMP_MOUNTS+=($bind_dest)
	done
	
	chroot "${chroot_dest}" $cmd || error "Failed to chroot into directory \"${chroot_dest}\" with cmd \"${cmd}\""
	
	sleep 1 # Wait for orphans before unmounting
	
	for ((i=0; i<${#__SYS_ADDITIONAL_BINDS[@]}; i=i+2))
	do
		bind_src=$(readlink -m "${__SYS_ADDITIONAL_BINDS[i]}")
		bind_dest=$(readlink -m "${chroot_dest}/${__SYS_ADDITIONAL_BINDS[i+1]}")
		umount "$bind_dest" || error "Failed to umount binded \"$bind_src\" into \"$bind_dest\""
		__sys_unset_tmp_mount $bind_dest
	done
	
	if [ -e "${chroot_dest}/proc/cmdline" ]; then
		umount "${chroot_dest}/proc" || error "Failed to umount ${chroot_dest}/proc"
		__sys_unset_tmp_mount "${chroot_dest}/proc"
	fi
	if [ -d "${chroot_dest}/sys/kernel" ]; then
		umount "$chroot_dest/sys" || error "Failed to umount ${chroot_dest}/sys"
		__sys_unset_tmp_mount "$chroot_dest/sys"
	fi
	if [ -e "${chroot_dest}/dev/pts/ptmx" ]; then
		umount "$chroot_dest/dev/pts" || error "Failed to umount ${chroot_dest}/dev/pts"
		__sys_unset_tmp_mount "$chroot_dest/dev/pts"
	fi
	if [ -e "${chroot_dest}/dev/mem" ]; then
		umount "${chroot_dest}/dev" || error "Failed to umount ${chroot_dest}/dev"
		__sys_unset_tmp_mount "${chroot_dest}/dev"
	fi
}

__sys_clean_mounts()
{
	local point
	for point in ${__SYS_TMP_MOUNTS[@]}
	do
		if [ "$(mount | grep "${point}")" != "" ] ; then
			notice "Lazy umount ${point}"
			umount -l "${point}" || true
		fi
	done
}

__sys_clean_tmpdirs()
{
	local dirpath
	for dirpath in ${__SYS_TMP_DIRS[@]}
	do
		if [ -d "${dirpath}" ] ; then
			rm -rf "${dirpath}" || true
		fi
	done
}

trap_exit_at_error __sys_clean_mounts
trap_exit_at_first __sys_clean_tmpdirs

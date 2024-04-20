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

# Copy dir contents into another dir with progress bar
# It will preserve all symlinks
# Usage: sys_cpdir /src/path /dst/path
sys_cpdir()
{
	if [ "$1" == "" ] || [ "$2" == "" ] ; then
		error "${FUNCNAME}: bad usage"
	fi
	if [ ! -d "$1" ] ; then
		error "${FUNCNAME}: source doesnt exist or its not a directory"
	fi
	if [ ! -r "$1" ] ; then
		error "${FUNCNAME}: source dir is not readable"
	fi
	if [ ! -x "$1" ] ; then
		error "${FUNCNAME}: source dir has no execute bit"
	fi
	if [ ! -d "$2" ] ; then
		error "${FUNCNAME}: destination doesnt exist or its not a directory"
	fi
	if [ ! -w "$2" ] ; then
		error "${FUNCNAME}: destination is not writeable"
	fi
	local size=$(du -sb ${1} | awk '{ print $1 }')
	tar -cf - -C ${1} ./ | pv -s ${size} -terabp | tar -xf - -C ${2}
}

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

# Temporary mount - will be unmounted at script exit
# Usage: sys_mount_tmp source destination [mount_args]
# Usage: sys_mount_tmp source (it will create temp directory and it will return it via echo)
sys_mount_tmp()
{
	local src="$1"
	local dst="$2"
	local ret=""
	
	if [ "$src" == "" ] ; then
		error "${FUNCNAME}: bad usage"
	fi
	
	if [ "$dst" == "" ] ; then
		dst=$(sys_mktempdir)
		ret="$dst"
	elif [ ! -d "$dst" ] ; then
		error "${FUNCNAME}: given destination path \"${dst}\" doesnt exist"
	fi
	
	dst=$(readlink -m "${dst}")
	
	if [ "$(mount | grep -F "${dst}")" != "" ] ; then
		error "${FUNCNAME}: ${dst} already mounted"
	fi
	
	__SYS_TMP_MOUNTS+=($dst)
	mount "$src" "$dst" ${@:3} || error "${FUNCNAME}: command failed: mount \"$src\" \"$dst\" ${@:3}"
	
	if [ "$ret" != "" ] ; then
		echo -n $ret
	fi
}

# Usage: sys_umount path_to_mount_point
sys_umount()
{
	if [ "$1" == "" ] || [ "$#" != 1 ] ; then
		error "${FUNCNAME}: bad usage"
	fi
	
	local path=$(readlink -m "${1}")
	
	umount "$path" || error "${FUNCNAME}: failed to umount \"${path}\""
	__sys_unset_tmp_mount $path
}

__sys_unset_tmp_mount()
{
	local i
	for i in ${!__SYS_TMP_MOUNTS[@]} ; do if [ "${__SYS_TMP_MOUNTS[i]}" == "$@" ] ; then unset __SYS_TMP_MOUNTS[i] ; fi ; done
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
	
	sys_mount_tmp proc "${chroot_dest}/proc" -t proc || error "Failed to mount /proc"
	#sys_mount_tmp /proc "$chroot_dest/proc" --bind || error "Failed to mount --bind /proc"
	
	sys_mount_tmp sys "${chroot_dest}/sys" -t sysfs || error "Failed to mount /sys"
	#sys_mount_tmp /sys "$chroot_dest/sys" --bind || error "Failed to mount --bind /sys"
	
	sys_mount_tmp devtmpfs "${chroot_dest}/dev" -t devtmpfs || error "Failed to mount /dev"
	#sys_mount_tmp --bind /dev "$chroot_dest/dev" --bind || error "Failed to mount --bind /dev"
	
	sys_mount_tmp devpts "${chroot_dest}/dev/pts" -t devpts || error "Failed to mount /dev/pts"
	#sys_mount_tmp --bind /dev/pts "$chroot_dest/dev/pts" || error "Failed to mount --bind /dev/pts"
	
	if [ "$(expr ${#__SYS_ADDITIONAL_BINDS[@]} % 2)" == "1" ] ; then
		error "${FUNCNAME}: elements num in \$__SYS_ADDITIONAL_BINDS should be even..." # another cant happen
	fi
	
	for ((i=0; i<${#__SYS_ADDITIONAL_BINDS[@]}; i=i+2))
	do
		bind_src=$(readlink -m "${__SYS_ADDITIONAL_BINDS[i]}")
		bind_dest=$(readlink -m "${chroot_dest}/${__SYS_ADDITIONAL_BINDS[i+1]}")
		
		if [ ! -d "${__SYS_ADDITIONAL_BINDS[i+1]}" ] ; then
			mkdir -p "${__SYS_ADDITIONAL_BINDS[i+1]}"
			chmod 755 "${__SYS_ADDITIONAL_BINDS[i+1]}"
		fi
		
		sys_mount_tmp "$bind_src" "$bind_dest" --bind || build_error "Failed to mount --bind \"$bind_src\" \"$bind_dest\""
	done
	
	chroot "${chroot_dest}" $cmd || error "Failed to chroot into directory \"${chroot_dest}\" with cmd \"${cmd}\""
	
	sleep 1 # Wait for orphans before unmounting
	
	for ((i=0; i<${#__SYS_ADDITIONAL_BINDS[@]}; i=i+2))
	do
		bind_src=$(readlink -m "${__SYS_ADDITIONAL_BINDS[i]}")
		bind_dest=$(readlink -m "${chroot_dest}/${__SYS_ADDITIONAL_BINDS[i+1]}")
		sys_umount "$bind_dest" || error "Failed to umount binded \"$bind_src\" into \"$bind_dest\""
	done
	
	if [ -e "${chroot_dest}/proc/cmdline" ]; then
		sys_umount "${chroot_dest}/proc"
	fi
	if [ -d "${chroot_dest}/sys/kernel" ]; then
		sys_umount "$chroot_dest/sys"
	fi
	if [ -e "${chroot_dest}/dev/pts/ptmx" ]; then
		sys_umount "$chroot_dest/dev/pts"
	fi
	if [ -e "${chroot_dest}/dev/mem" ]; then
		sys_umount "${chroot_dest}/dev"
	fi
}

# Get partition offset (device or image file) in sectors.
# Usage: sys_partition_get_offset device partition_number
sys_partition_get_offset()
{
	sgdisk -i "$2" "$1" | grep -F "First sector" | awk '{print $3}'
}

# Get partition offset (device or image file) in bytes.
# Usage: sys_partition_get_offset_in_bytes device partition_number
sys_partition_get_offset_in_bytes()
{
	local sectors=$(sys_partition_get_offset $@)
	echo $((sectors*512))
}

# Get partition size (device or image file) in sectors.
# Usage: sys_partition_get_size device partition_number
sys_partition_get_size()
{
	sgdisk -i "$2" "$1" | grep -F "Partition size" | awk '{print $3}'
}

# Get partition size (device or image file) in bytes.
# Usage: sys_partition_get_size_in_bytes device partition_number
sys_partition_get_size_in_bytes()
{
	local sectors=$(sys_partition_get_size $@)
	echo $((sectors*512))
}

sys_partition_get_last_sector()
{
	sgdisk -i "$2" "$1" | grep -F "Last sector" | awk '{print $3}'
}

__sys_clean_mounts()
{
	local point
	for point in ${__SYS_TMP_MOUNTS[@]}
	do
		if [ "$(mount | grep -F "${point}")" != "" ] ; then
			notice "Lazy umount ${point}"
			umount -l "${point}" || true
		else
			notice "Directory \"${point}\" was mounted via sys_mount_tmp(), but it wasnt unmounted via sys_umount()"
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

# NOTE: __sys_clean_mounts must be before __sys_clean_tmpdirs
trap_exit_at_error __sys_clean_mounts
trap_exit_at_first __sys_clean_tmpdirs

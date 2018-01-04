#!/bin/bash

MIRROR=http://ftp.vectranet.pl/gentoo
STAGE_FILE=stage3-i686-20160726
D_ARCH=x86

PORTAGE_FILE=portage-latest.tar.bz2

# root directory
ROOT='ROOT'

IMAGE_FILE='release.img'

# if set, freshroot/tmproot would mount ROOT as tmpfs
MOUNT_TMPFS=false

NOUPDATE_FSTAB=false
DEVICE_NAME='sda'

# packages to emerge in chroot
PACKAGES=""

# kernel version
KERNEL="gentoo-sources"

# temporary root path
TMPROOT='.tmp_root'

REBUILD_SYSTEM=false

SYNC_DIRS=""
WRITE_DEV="/dev/sde"

EXCLUDE=''

AVAILABLE_COMMANDS=(freshroot create_image chroot dropshell build_system emerge write mount_image umount_image)

# commands to be called
COMMANDS=()

SELF=$0
ARGS=$@

VERBOSE=1
NOREDIROUT=false

# utilities
pprint() {
    color=$1
    color2=$2
    msg=$3
    echo $(tput bold)$(tput setaf ${color}) \* $(tput sgr0)$(tput setaf ${color2})${msg}$(tput sgr0)
}

pbold() {
    echo $(tput bold)$(tput setaf 2) \* $(tput sgr0)$(tput bold)${@}$(tput sgr0)
}

pinfo() {
    pprint 2 7 "$@"
}

pwarn() {
    pprint 7 3 "$@"
}

perr() {
    pprint 1 1 "$@"
}

do_cmd() {
	cmdname=""
	run=""
	for par in $@ ; do
		run="${run} ${par}"
		if [[ "${par}" == '|' ]] ; then cmdname=""; 
		elif [[ "${cmdname}" == "" ]] ; then cmdname=${par}; fi
	done
	
	if [[ $VERBOSE -gt 1 ]] ; then pprint 4 7 "${run}"; fi
	if $NOREDIROUT ; then
		eval ${run}
	else
		eval ${run} >/tmp/.stdout 2>/tmp/.stderr
	fi
	r=$?
	
	exp_ret=0	
	
	if [[ $r != $exp_ret ]] ; then
		perr "Error during executing ${cmdname}"
		cat /tmp/.stderr | while read line ; do
			pprint 1 7 "${line}"
		done
		exit
	fi
	
	rm /tmp/.std{out,err} 2>/dev/null
	return $r
}

clear_loopbacks() {
# release previously used loop
    losetup -j "${IMAGE_FILE}" | while read line ; do 
         dev=$(echo $line | cut -d":" -f1)
         pinfo "Removing $dev"
         do_cmd losetup -d $dev
         do_cmd losetup -j "${IMAGE_FILE}" | grep ${dev} >/dev/null
         if [ $? == 0 ] ; then
             pwarn "NOTICE:"
             pwarn "Could not remove loopback device $dev"
             pwarn "It's probably left from previous Gaston call"
             pwarn "You have to take care of it manually"
         fi
    done
}

cmd_freshroot() {
    if [ ! -d "${ROOT}" ] || [ "$(ls -A ${ROOT})" == "" ]; then
        pinfo "Creating ROOT directory [${ROOT}]"
        do_cmd mkdir -p "${ROOT}"
        
        if $MOUNT_TMPFS; then
            pinfo "Mounting ROOT as tmpfs"
            do_cmd mount -t tmpfs tmpfs -o size=4G "${ROOT}"
        fi
        
        if [ ! -f "${STAGE_FILE}.tar.bz2" ] ; then
            pinfo "Fetching stage3 file"
            dn="current"
            p=""
            for s in ${STAGE_FILE//-/ } ; do 
                if [[ "${p}" != "" ]]; then dn="${dn}-${p}"; fi
                p=${s}
            done

            do_cmd wget -q "${MIRROR}/releases/${D_ARCH}/autobuilds/${dn}/${STAGE_FILE}.tar.bz2"
        fi
        
        pinfo "Unpacking stage3 into ${ROOT}"
        do_cmd tar xjpf "${STAGE_FILE}.tar.bz2" -C "${ROOT}"

        if [ ! -f ${PORTAGE_FILE} ] ; then
            pinfo "Fetching portage tree"
            do_cmd wget -q "${MIRROR}/snapshots/portage-latest.tar.bz2"
        fi
        
        pinfo "Unpacking portage into ${ROOT}"
        do_cmd tar xjf ${PORTAGE_FILE} -C "${ROOT}/usr/"
    fi
}


cmd_dropshell() {
    pinfo "You're now in your fresh chrooted system"
    pinfo "What you see here, you'll get on your dest"
    pinfo "(press Ctrl+D or type exit to quit"

    env-update
    source /etc/profile
    echo export PS1="\"(chroot) $PS1\"" > /etc/profile.d/99ps.sh
    source /etc/profile

    ${SHELL} --noprofile --norc -i
    
    rm /etc/profile.d/99ps.sh
}


cmd_emerge() {
    env-update && source /etc/profile
    DONT_MOUNT_BOOT=1 emerge --quiet-build --quiet-fail --quiet-unmerge-warn ${PACKAGES}
}


cmd_chroot() {
    if [[ "${1}" == "" ]] ; then
        cmd="dropshell"
    else
        cmd="${1}"
    fi
    cmd_freshroot

    mount | grep "${ROOT}/proc"
    if [ $? == 1 ]; then
        do_cmd mount -t proc proc "${ROOT}/proc"
    fi
    mount | grep "${ROOT}/dev" >/dev/null
    if [ $? == 1 ]; then
        do_cmd mount -o bind /dev "${ROOT}/dev"
    fi
    mount | grep "${ROOT}/dev/shm" >/dev/null
    if [ $? == 1 ]; then
        do_cmd mount -t tmpfs tmpfs "${ROOT}/dev/shm"
    fi

    do_cmd cp ${SELF} "${ROOT}/bin/"
    if [ ! -f "${ROOT}/etc/resolv.conf" ]; then
        do_cmd cp /etc/resolv.conf "${ROOT}/etc/"
    fi
    
    repass=""
    for p in ${PACKAGES}; do
        repass="${repass} --package=${p}"
    done

    c='${SHELL} /bin/gaston.sh '"${repass} ${cmd}"
    
    bits="linux32"
    if [[ $(uname -m) == "x86_64" ]] && [[ "$D_ARCH" == *64 ]] ; then
        bits="linux32"
    fi
    
    NOREDIROUT=true
    do_cmd $bits chroot "${ROOT}" ${SHELL} -i -c "\"${c}\""
    NOREDIROUT=false

    do_cmd rm "${ROOT}/bin/gaston.sh"
    do_cmd umount "${ROOT}/proc"
    do_cmd umount "${ROOT}/dev/shm"
    do_cmd umount "${ROOT}/dev"
}


cmd_build_system() {
    if [ ! -f "${ROOT}/boot/grub/grub.conf" ] ; then
        PACKAGES="${PACKAGES} sys-boot/grub"
    fi
    
    if [ ! -d "${ROOT}/usr/src/linux" ] ; then
        PACKAGES="${PACKAGES} sys-kernel/${KERNEL}"
    fi

    if $REBUILD_SYSTEM ; then
        PACKAGES="${PACKAGES} @installed"
    fi
    
    if [[ "${PACKAGES}" != "" ]] ; then
    echo ${PACKAGES}
    ls  /boot/grub/
        cmd_chroot emerge
    fi
}


cmd_create_image() {
    cmd_umount_image
    cmd_build_system
    
    if [ ! $PART_COUNT ] ; then
        perr "No partitions defined. Aborting"
        return
    fi
    
    # update fstab
    if ! $NOUPDATE_FSTAB ; then
        for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
            type=$(eval echo \$PART_${i}_TYPE)
            name=$(eval echo \$PART_${i}_PATH)
            
            sed -i -e "/\W${name/\//\\\/}\W/d" "${ROOT}/etc/fstab"
            echo -e "/dev/${DEVICE_NAME}$(( 1 + ${i} ))\t${name}\t${type}\t noatime\t 0 0" >> "${ROOT}/etc/fstab"
        done
    fi

    # prepare sqashes and calculate size
    ROOT_SIZE=0
    _has_root=false
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        type=$(eval echo \$PART_${i}_TYPE)
        name=$(eval echo \$PART_${i}_PATH)
        src=$(eval echo \$PART_${i}_SRC)

        if [[ "$type" == "squashfs" ]] ; then
            ex1=''
            for (( j = 0; j < ${i} ; j++ )) ; do 
                e=$(eval echo \$PART_${j}_PATH)
                ex1="${ex1} ${e:1}/*"
            done
            for (( j = $(( 1 + ${i} )); j < ${PART_COUNT};  j++ )) ; do 
                e=$(eval echo \$PART_${j}_PATH)
                ex1="${ex1} ${e:1}/*"
            done
            
            e=""
            for ee in ${EXCLUDE} ${ex1} ; do e="${e} -e ${ee}" ; done
            name_=${name//\//_}
            if [ -f "${name_}.squashfs" ] ; then rm "${name_}.squashfs"; fi
            pinfo "Creating squashfs partition ($name)"
            do_cmd mksquashfs "${src}" "${name_}.squashfs" -no-progress -comp gzip -Xcompression-level 1 $e 
            s=$(stat -c%s "${name_}.squashfs")
            s=$(( ( 1 + $s / 1024 / 1024 ) * 1024 * 1024 ))
            eval PART_${i}_SIZE=$s
            ROOT_SIZE=$(( $ROOT_SIZE + $s ))
        else
            ROOT_SIZE=$(( $ROOT_SIZE + $(eval echo \$PART_${i}_SIZE) ))
        fi
        
        if [ $name == '/' ] || [ $name == '' ] ; then
            _has_root=true
        fi
    done
    
    if ! $_has_root ; then
        perr "There is no ROOT ('/') partition defined."
        perr "You have to define one root partition and up to three other"
        return
    fi
    
    ROOT_SIZE_MB=$(( $ROOT_SIZE / 1024 / 1024 + ${PART_COUNT} ))
    
    pinfo "Creating disk image (size=${ROOT_SIZE_MB}MB)"
    do_cmd do_cmd dd if=/dev/zero of=$IMAGE_FILE bs=1M count=$ROOT_SIZE_MB
    
    
    pinfo "Partitioning image"
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        size=$(eval echo \$PART_${i}_SIZE)
        size_m=$(( $size / 512 ))
        do_cmd echo -e 'n\\np\\n\\n\\n+${size_m}\\nw' '|' fdisk ${IMAGE_FILE}
    done
    
    pinfo "Writing data into image"
    if [ ! -d $TMPROOT ] ; then
        mkdir $TMPROOT
    fi
    
    lo_all=$(losetup -f)
    losetup ${lo_all} ${IMAGE_FILE}    
    
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        type=$(eval echo \$PART_${i}_TYPE)
        name=$(eval echo \$PART_${i}_PATH)
        src=$(eval echo \$PART_${i}_SRC)
    
        l=($(fdisk -l ${IMAGE_FILE} | grep "${IMAGE_FILE}$(( 1 + ${i} ))" | tr -s ' '))
        lo=$(losetup -f)
        
        pinfo " - ${name} with size $(( ${l[3]} * 512 / 1024 / 1024 ))MB"
        do_cmd losetup -o $(( ${l[1]} * 512 )) --sizelimit $(( ${l[3]} * 512 )) ${lo} ${IMAGE_FILE}
        
        ex1=''
        for (( j = 0; j < ${i} ; j++ )) ; do 
            e=$(eval echo \$PART_${j}_PATH)
            ex1="${ex1} ${e:1}/"
        done
        for (( j = $(( 1 + ${i} )); j < ${PART_COUNT};  j++ )) ; do 
            e=$(eval echo \$PART_${j}_PATH)
            ex1="${ex1} ${e:1}/"
        done
        e=""
        for ee in ${EXCLUDE} ${ex1} ; do e="${e} --exclude ${ee}" ; done

        if [[ $type == 'squashfs' ]] ; then
            name_=${name//\//_}
            do_cmd dd if=${name_}.squashfs of=$lo bs=1M
        else
            do_cmd mkfs.$type $lo
            do_cmd mount ${lo} "${TMPROOT}"
            do_cmd rsync -a --delete ${e} "${src}/" "${TMPROOT}/"
            for sd in ${SYNC_DIRS} ; do
                t=(${sd//:/ })
                if [[ ${t[1]} == *${name}* ]] ; then
                    dst=${t[1]}
                    do_cmd rsync -a ${t[0]} "${TMPROOT}/${dst:${#name}}"
                fi
            done
            do_cmd umount "${TMPROOT}"
        fi

        do_cmd losetup -d $lo
    done


    # toggle bootable
    do_cmd echo -e 'a\\n1\\nw' '|' fdisk ${IMAGE_FILE}
    
    pinfo "Installing bootloader"
    if [ ! -d "${ROOT}/boot/grub" ] ; then
        pwarn "There is no grub on your new system"
        pwarn "Call gaston with \"build_system\" or \"chroot\" and emerge sys-boot/grub"
        pwarn "Until that, your image is *NOT* bootable!"
    else
        do_cmd echo -e '"device (hd0) ${IMAGE_FILE}\\nroot (hd0,0)\\nsetup (hd0)"' '|' grub --batch
    fi

    pinfo "Cleaning up"
    do_cmd losetup -d ${lo_all}
    do_cmd rmdir ${TMPROOT}

    # remove squashfs files
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        name=$(eval echo \$PART_${i}_PATH)
        name_=${name//\//_}
        if [ -f "${name_}.squashfs" ] ; then do_cmd rm "${name_}.squashfs" ; fi
    done
}

cmd_mount_image() {
    clear_loopbacks
    
    if [ ! -d $TMPROOT ] ; then
        do_cmd mkdir $TMPROOT
    fi
    
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        name=$(eval echo \$PART_${i}_PATH)
        
        if [[ "$name" == "/" ]] ; then
            lo=$(losetup -f)
            l=($(fdisk -l ${IMAGE_FILE} | grep "${IMAGE_FILE}$(( 1 + ${i} ))" | tr -s ' '))
            do_cmd losetup -o $(( ${l[1]} * 512 )) --sizelimit $(( ${l[3]} * 512 )) ${lo} ${IMAGE_FILE}
            do_cmd mount $lo $TMPROOT
        fi
    done

    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        name=$(eval echo \$PART_${i}_PATH)
        
        if [[ "$name" != "/" ]] ; then
            lo=$(losetup -f)
            l=($(fdisk -l ${IMAGE_FILE} | grep "${IMAGE_FILE}$(( 1 + ${i} ))" | tr '*' ' ' | tr -s ' '))
            do_cmd losetup -o $(( ${l[1]} * 512 )) --sizelimit $(( ${l[3]} * 512 )) ${lo} ${IMAGE_FILE}
            do_cmd mount $lo $TMPROOT/$name
        fi
    done
}

cmd_umount_image() {
    for (( i = 0 ; i < ${PART_COUNT}; i++ )) ; do
        name=$(eval echo \$PART_${i}_PATH)

        if [[ "$name" != "/" ]] && [[ -d "${TMPROOT}/${name}" ]] ; then
            do_cmd umount $TMPROOT/$name
        fi
    done

    if [[ -d "${TMPROOT}/" ]]; then
        if mount | grep "${TMPROOT}" ; then
            do_cmd umount $TMPROOT/
        fi
    fi

    clear_loopbacks
}

cmd_write() {
    if [ -b ${WRITE_DEV} ] ; then
    do_cmd dd if=/dev/zero of=${WRITE_DEV} bs=1M count=1 conv=fsync
    do_cmd dd if=${IMAGE_FILE} of=${WRITE_DEV} bs=1M conv=fsync
    do_cmd eject ${WRITE_DEV}
    else
      perr "No such device: ${WRITE_DEV}"
    fi
}

create_makefile() {
    if [[ -f Makefile ]] ; then
        if ! head -n1 Makefile | grep gaston ; then
            mv Makefile Makefile.bak
        fi
    fi
    
    echo '# created with Gaston (GentooCNC)' > Makefile
    echo 'OPTS=""' >> Makefile
    for i in ${ARGS} ; do
        if [[ "${i::1}" == "-" ]] ; then
            echo 'OPTS+='${i} >> Makefile
        fi
    done
    cat >>Makefile <<EOF
%:
	sh ${SELF} \$(OPTS) \$@
EOF

}

main() {
    if [ ${UID} != 0 ] ; then
        perr "You supossed to be root to do this"
        exit
    fi
    
    CMD=$1
    pbold Running: ${CMD}
    eval "cmd_$CMD"
}


indexOf() {
    val=$1
    shift
    ar=($@)

    for (( i = 0; i < ${#ar[@]}; i++ )); do
    if [ "${ar[$i]}" = "${val}" ]; then
        echo $i
        return
    fi
    done

    echo -1
}

parse_partitions() {
    i=0
    p=(${1//,/ })
    for part in ${p[@]} ; do
        p_data=(${part//:/ });
        name=${p_data[0]}
        if [[ "${name:0:1}" != "/" ]] ; then
            pwarn "Partition names should start with slash ('/')"
            name="/${name}"
        fi
        
        eval PART_${i}_PATH=$name
        eval PART_${i}_TYPE=${p_data[1]}

        if [[ ${#p_data[*]} -gt 2 ]] ; then
            size=${p_data[2]}
            if [[ "$size" == "auto" ]] || [[ "$size" == "" ]] ; then
                if [[ ${p_data[1]} != "squashfs" ]] ; then
                    perr "Auto size is available only with squashfs filesystem"
                    perr "When declaring other system type you have to define it's size"
                    exit
                fi
                
                size='auto'
            else
            
                suffix=${size:$((${#size}-1)):1}
                if [[ "(m M k K g G t T)" == *"$suffix"* ]] ; then
                    size=${size:0:$((${#size}-1))}
                    case $suffix in
                        k|K)
                        size=$(( $size * 1024 ))
                        ;;
                        m|M)
                        size=$(( $size * 1024 ** 2 ))
                        ;;
                        g|G)
                        size=$(( $size * 1024 ** 3 ))
                        ;;
                        t|T)
                        size=$(( $size * 1024 ** 4 ))
                        ;;
                    esac
                fi
            fi
            
            eval PART_${i}_SIZE=${size}
            
            if [[ ${#p_data[*]} -gt 3 ]] ; then
                eval PART_${i}_SRC=${p_data[3]}
            else
                eval PART_${i}_SRC="${ROOT}/$name"
            fi
        else
            eval PART_${i}_SRC="${ROOT}/$name"
        fi
        
        i=$(( $i + 1 ))
    done
    PART_COUNT=$i

    if [ ${PART_COUNT} -gt 4 ] ; then
        perr "Cannot create more that 4 partitions"
        perr "Only primary partitions are supported by Gaston now, sorry"
        exit
    fi
}

parse_options() {
    local partitions=""
    params=$(getopt -o "vh" -l "help,verbose,mirror:,root-dir:,mount-tmpfs,partition:,partitions:,exclude:,noupdate-fstab,disk-device:,package:,kernel:,sync-dirs:,write-dev:,arch:,stage:,makefile" -n "$0" -- "$@")
    eval set -- "$params"
    while true; do
        case "$1" in
        --)
            shift
            break
        ;;
        -h|--help)
            echo "GASTON ($0) is a smart tool for easy creating"
            echo "and manipulation of Gentoo based system images"
            echo
            echo "General usage:"
            echo "./gaston.sh [OPTIONS] [COMMANDS]"
            echo 
            echo "Available options:"
            echo "    --root-dir    Path to directory, where chrooted system exists/should "
            echo "                  be created"
            echo "    --mount-tmpfs New ROOT directory should be created in memory instead"
            echo "                  of on hard disk. That way all operations would be much"
            echo "                  faster, but you'll loose all data when umount it"
            echo "    --partition=  Partition definition to be created when creating image"
            echo "                  See: Defining partitions below"
            echo "    --exclude     Do not add this file/directory into destination image"
            echo "                  Can be defined multiple times"
            echo "                  Example: --exclude usr/portage --exclude usr/src"
            echo "    --noupdate-fstab Do not update /etc/fstab on new system; as default"
            echo "                  gaston will create fstab basing on partition list"
            echo "    --disk-device Disk device name on destination system (usually sda)"
            echo "    --package     Emerge this package under your ROOT"
            echo "    --kernel      Use kernel with given name (default: gentoo-sources)"
            echo "    --sync-dirs   Synchronize pair of directories (src->dst)"
            echo "                  This parameter value has to be in form SRC:DST, where"
            echo "                  SRC - is source directory from where files are synced"
            echo "                  DST - directory under --root-dir where to put files"
            echo "                  Files are synchronized with ROOT while creating image"
            echo "    --mirror      Set mirror base address"
            echo "    --write-dev   Device to write image (/dev/sde)"
            echo "    --arch        Set architecture name (x86, amd64)"
            echo "    --stage       Set stage3 filename (stage3-i686-20141202)"
            echo "    --verbose     Print commands to execute"
            echo "    --makefile    Create Makefile as common interface to make gaston "
            echo "                  easier"
            echo
            echo "Available commands"
            echo "    freshroot     Create new ROOT directory, with base Gentoo system"
            echo "                  inside"
            echo "    create_image  Prepare raw image based on ROOT directory"
            echo "    chroot        Chroot into ROOT system"
            echo "    write         Write image into block device"
            echo "    mount_image   Mount created image as loopback device"
            echo "    umount_image  Unmount previously mounted image"
            echo
            echo "Defining patitions:"
            echo "    When creating system image, Gaston has to know list of partitions"
            echo "    it has to create (their mountpoint, type, size and source)."
            echo "    You have to pass them as --partition=PART_DEF (can be of course"
            echo "    issued multiple times)."
            echo "    Each PART_DEF is in form of: PATH:TYPE:SIZE:SRC"
            echo "    Where:"
            echo "      - PATH - mountpoint on destination system (/boot, /, etc)"
            echo "      - TYPE - filesystem, can be anything your system can talk to"
            echo "               'squashfs' is handled in special way"
            echo "      - SIZE - partition size or 'auto' (only appliable for squashfs)"
            echo "      - SRC  - directory, from where files would be copied into image"
            echo "               by default it's ROOT_DIR/PATH"
            echo
            echo "Example usage:"
            echo "sh gaston.sh --partition /boot:ext2:50m \ "
            echo "    --partition /:squashfs: --partition home:ext2:100m:/tmp/test \ "
            echo "    --exclude usr/portage --exclude=usr/src --exclude usr/include \ "
            echo "    create_image "

            shift
        ;;
        -v|--verbose)
            VERBOSE=2
            shift
        ;;
        --mirror)
            shift
            MIRROR="$1"
            shift
        ;;
        --mount-tmpfs)
            MOUNT_TMPFS=true
            shift
        ;;
        --noupdate-fstab)
            NOUPDATE_FSTAB=true
            shift
        ;;
        --root-dir)
            shift
            ROOT="${1}"
            shift
        ;;
        --disk-device)
            shift
            DEVICE_NAME=${1}
            shift
            ;;
        --partitions)
            shift
            partitions=$1
            shift
        ;;
        --partition)
            shift
            if [ "${partitions}" == "" ] ; then
                partitions=${1}
            else
                partitions="${partitions},${1}"
            fi
            shift
        ;;
        --makefile)
            create_makefile
            shift
        ;;
        --package)
            shift
            PACKAGES="${PACKAGES} ${1}"
            shift
            ;;
        --exclude)
            shift
            EXCLUDE="${EXCLUDE} ${1}"
            shift
            ;;
        --kernel)
            shift
            KERNEL="${1}"
            shift
            ;;
        --sync-dirs)
            shift
            SYNC_DIRS="${SYNC_DIRS} ${1}"
            shift
            ;;
        --write-dev)
            shift
            WRITE_DEV="${1}"
            shift
            ;;
        --arch)
            shift
            D_ARCH="${1}"
            shift
            ;;
        --stage)
            shift
            STAGE_FILE="${1}"
            if [[ "${STAGE_FILE}" == *.tar.bz2 ]] ; then
                STAGE_FILE=${STAGE_FILE:0:$(( ${#STAGE_FILE} - 8 ))}
            fi
            shift
            ;;
        *) 
            pwarn 'WARNING! '
            pwarn 'unhandled parameter:'$1

            shift
        ;;
        esac
    done
    
    parse_partitions ${partitions}
    
    while true; do
        if [ "$1" == "" ] ; then break ; fi
        r=$(indexOf "$1" "${AVAILABLE_COMMANDS[@]}")
        if [ $r -lt 0 ] ; then
            perr "Unknown command \"$1\", see --help"
            exit 1
        fi
        
        COMMANDS+=($1)
        shift
    done
}


parse_options $@
for cmd in "${COMMANDS[@]}" ; do
    main ${cmd};
done

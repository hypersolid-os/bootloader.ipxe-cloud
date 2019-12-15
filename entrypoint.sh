#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0

# Fail on Error !
set -e

export VIRTUAL_DISK=/tmp/disk.img

# container build ready - attach to interactive bash
if [ -f "/.buildready" ]; then
    # just start bash
    /bin/bash
    exit 0
else
    touch /.buildready
fi

# create mount point
mkdir -p /mnt/

# Create sparse file to represent our disk
truncate --size 512M $VIRTUAL_DISK

# Create partition layout
# set "Legacy BIOS bootable flag" for boot parition (tag required by gptmbr.bin)
sgdisk --clear \
  --new 1::+10M --typecode=1:8300 --change-name=1:'extlinux' --attributes=1:set:2 \
  --new 2::-0 --typecode=2:8300 --change-name=2:'config' \
  ${VIRTUAL_DISK}

# show layout
gdisk -l ${VIRTUAL_DISK}

# show additional attributes
sgdisk ${VIRTUAL_DISK} --attributes=1:show

# add mbr code
dd bs=440 count=1 conv=notrunc if=/usr/lib/EXTLINUX/gptmbr.bin of=${VIRTUAL_DISK}

# mount disk
LOOPDEV=$(losetup --find --show --partscan ${VIRTUAL_DISK})

# create filesystems
mkfs.ext2 ${LOOPDEV}p1
mkfs.ext4 ${LOOPDEV}p2

# mount boot partition
mkdir -p /mnt/boot
mount ${LOOPDEV}p1 /mnt/boot

# create extlinux dir
mkdir -p /mnt/boot/extlinux

# initialize extlinux (stage2 volume boot record + files)
extlinux --install /mnt/boot/extlinux

# copy config files, ipxe
cp -R /opt/. /mnt/boot/extlinux

# detach loop device
losetup --detach $LOOPDEV
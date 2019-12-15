hypersolid bootloader for cloudservers/virtual maschines
=========================================================

**boot hypersolid via [MBR -> syslinux -> ipxe] chaining**

Use case
=============

Within cloud environments/virtual servers there is mostly no possibility to use pxe-boot directly to load ipxe (which is the recommend method to deploy hypersolid on server systems).

As a workaround, we use [syslinux/extlinux](https://wiki.syslinux.org/wiki/index.php?title=EXTLINUX) as bootloader to chainload [ipxe](http://http://ipxe.org/) which can for example retrieve a configuration file via https.

How to deploy
===================

Most hosting providers offering a rescue-system or supports raw system images directly.

The final image can be directly copied onto the boot disk of the system using dd:

```bash
gzip -d -c boot.img.gz | dd bs=4M status=progress of=/dev/sdX
```

Build image
===================

This bootloader generator creates a raw GPT disk image with 2 paritions (boot, config) including all required bootloader files + configs. The build environment is isolated within a docker container but requires full system access (privileged mode) due to the use of loop devices.

To build the disk image, you have do add the `ipxe.lkrn` binary into `ipxe/` directory. 

Finally run `build.sh` to build the docker image and trigger the image build script. The disk image will be copied into the `dist/` directory.

```txt
 $ ./build.sh 
Sending build context to Docker daemon  6.144kB
Step 1/7 : FROM debian:buster as build
 ---> 8e9f8546050d
Step 2/7 : ENV DEBIAN_FRONTEND=noninteractive
 ---> Using cache
 ---> 818ca9c1ef88
Step 3/7 : WORKDIR /opt
 ---> Using cache
 ---> 6c85e942c228
Step 4/7 : RUN set -xe     && apt-get update     && apt-get -y --no-install-recommends         install extlinux gdisk
 ---> Using cache
 ---> 88de8edd75b4
Step 5/7 : COPY entrypoint.sh /entrypoint.sh
 ---> Using cache
 ---> 041ee0bfa8f9
Step 6/7 : ENTRYPOINT [ "/bin/bash" , "-c"]
 ---> Using cache
 ---> d998cea2da5a
Step 7/7 : CMD [ "/entrypoint.sh" ]
 ---> Using cache
 ---> 5e54c23470ac
Successfully built 5e54c23470ac
Successfully tagged hypersolid-boot-cloudserver:latest
hypersolid-boot-cloudserver-env
Creating new GPT entries.
Setting name!
partNum is 0
Setting name!
partNum is 1
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot or after you
run partprobe(8) or kpartx(8)
The operation has completed successfully.
GPT fdisk (gdisk) version 1.0.3

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

Found valid GPT with protective MBR; using GPT.
Disk /opt/build/disk.img: 1048576 sectors, 512.0 MiB
Sector size (logical): 512 bytes
Disk identifier (GUID): DA307D18-07FB-4605-B630-EF355CBF2F2A
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 1048542
Partitions will be aligned on 2048-sector boundaries
Total free space is 2014 sectors (1007.0 KiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048           22527   10.0 MiB    8300  extlinux
   2           22528         1048542   501.0 MiB   8300  config
1:2:1 (legacy BIOS bootable)
1+0 records in
1+0 records out
440 bytes copied, 2.8426e-05 s, 15.5 MB/s
mke2fs 1.44.5 (15-Dec-2018)
Discarding device blocks: done                            
Creating filesystem with 10240 1k blocks and 2560 inodes
Filesystem UUID: 6f541550-18d7-4ca1-a69c-f402dcac4c37
Superblock backups stored on blocks: 
        8193

Allocating group tables: done                            
Writing inode tables: done                            
Writing superblocks and filesystem accounting information: done

mke2fs 1.44.5 (15-Dec-2018)
Discarding device blocks: done                            
Creating filesystem with 513004 1k blocks and 128520 inodes
Filesystem UUID: 3b6cd75b-249c-4790-9436-52eaa797750e
Superblock backups stored on blocks: 
        8193, 24577, 40961, 57345, 73729, 204801, 221185, 401409

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

/mnt/boot/extlinux is device /dev/loop0p1
Warning: unable to obtain device geometry (defaulting to 64 heads, 32 sectors)
         (on hard disks, this is usually harmless.)
```

Boot stages
===================

0. host system loads the initial bootloader (e.g. SeaBIOS) | hostsystem
1. BIOS loads the MBR bootcode (`gptmbr.bin`) at the start of the root disk | extlinux-stage1
2. extlinux mbr code searches for the first active partition | extlinux-stage1
3. extlinux mbr code executes the volume boot records of the active partition (contains the inode address of `ldlinux.sys`) | extlinux-stage2
4. extlinux loads the rest of `ldlinux.sys` | extlinux-stage3
5. extlinux loads `ldlinux.c32` core bootloader module | extlinux-stage4
6. extlinux core module searches for the configuration file `extlinux/extlinux.conf` and loads it | extlinux-stage5
7. extlinux loads+executes the `ipxe.krnl` code which includes a full featured ipxe bootloader | ipxe-stage1

Partition layout
===================

This bootloader generator creates a GPT based partition layout (of course, syslinux can handle it).

* Partition 1 "boot" - `10MB` | `EXT2` (required for extlinux!) | bootloader partition including extlinux+ipxe
* Partition 2 "conf" - `500MB` | `EXT4` | persistent data storage partition

IPXE binary
===================

The [iPXE](http://ipxe.org) binary can be build from source (to include an embedded config file) or retrieved from the [official website](http://ipxe.org)


License
----------------------------

**hypersolid** is OpenSource and licensed under the Terms of [GNU General Public Licence v2](LICENSE.txt). You're welcome to [contribute](CONTRIBUTE.md)!
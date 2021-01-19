#!/bin/bash
#install depends packets
apt install debootstrap kpartx qemu-kvm
#edk2 depends
apt install acpica-tools nasm libx11-dev libxext-dev
#grub depends
sudo apt install -y libdevmapper-dev fonts-dejavu libfuse-dev ttf-dejavu libzfslinux-dev liblzma-dev flex bison

if test -z "$DESTDIR"                                                                                                                                                                                                
then                                                                                                                                                                                                                 
	echo "the DESTDIR of haoos is not set"
	DESTDIR=`pwd`
	echo "set the default path $DESTDIR"
else                                                                                                                                                                                                                 
	echo "DESTDIR is set to $DESTDIR!"
fi 

HAOOS_DIR=$DESTDIR
SUB_DIR=$DESTDIR/submodules
ISO_DIR=$HAOOS_DIR/iso
SCRIPTS_DIR=$HAOOS_DIR/iso/scripts
KERNEL_VERSION=`uname -r`

echo "start" > log.txt
if [ ! -e $ISO_DIR ];then
	mkdir -p $ISO_DIR
fi

#make iso and mount file
# create the hd disk img
if [ ! -e $ISO_DIR/haoos.img ];then
    dd if=/dev/zero of=$ISO_DIR/haoos.img bs=1G count=10
else
    echo "$ISO_DIR/haoos.img exists" >> log.txt
fi
#
if [ ! -e /dev/loop200 ];then
    echo "/dev/loop200 not exists" >> log.txt 
    mknod /dev/loop200 b 7 200
else
    echo "/dev/loop200 already exists" >> log.txt 
fi
#
losetup /dev/loop200 $ISO_DIR/haoos.img
fdisk /dev/loop200 << EOF
g
n
1

+100M
n
2

+100M
n
3


p
w
EOF
kpartx -av /dev/loop200
mkfs.fat /dev/mapper/loop200p1
mkfs.ext4 /dev/mapper/loop200p2
mkfs.ext4 /dev/mapper/loop200p3
#
# >>>GRUB DIR<<<
if [ ! -e $ISO_DIR/grub ];then
    mkdir $ISO_DIR/grub -p
    mount /dev/mapper/loop200p1 $ISO_DIR/grub
    echo "mount /dev/mapper/loop200p1 to $ISO_DIR/grub" >> log.txt 
else
    if ! mountpoint -q $ISO_DIR/grub ;then
        mount /dev/mapper/loop200p1 $ISO_DIR/grub
        echo mount /dev/mapper/loop200p1 to $ISO_DIR/grub >> log.txt 
    fi
fi
#install grub
if [ ! -e $SUB_DIR/grub2/grub-install ];then
    $SUB_DIR/grub2/configure
    make -C $SUB_DIR/grub2 -j32
fi

if [ ! -e $ISO_DIR/grub/EFI/grub/grubx64.efi ];then
echo "$SUB_DIR/grub2/grub-install \
    --boot-directory=$HAOOS_DIR/iso/grub \
    --efi-directory=$HAOOS_DIR/iso/grub \
    --directory=/usr/lib/grub/x86_64-efi /dev/mapper/loop200p1" >> log.txt 
$SUB_DIR/grub2/grub-install \
    --boot-directory=$HAOOS_DIR/iso/grub \
    --efi-directory=$HAOOS_DIR/iso/grub \
    --directory=/usr/lib/grub/x86_64-efi /dev/mapper/loop200p1
fi

# >>>BOOT DIR<<<
if [ ! -e $ISO_DIR/boot ];then
    mkdir $ISO_DIR/boot -p
    mount /dev/mapper/loop200p2 $ISO_DIR/boot
    echo "mount /dev/mapper/loop200p2 to $ISO_DIR/boot" >> log.txt 
else
    if ! mountpoint -q $ISO_DIR/boot ;then
        mount /dev/mapper/loop200p2 $ISO_DIR/boot
        echo mount /dev/mapper/loop200p2 to $ISO_DIR/boot >> log.txt 
    fi
fi
# copy the 'vmlinuz' and 'initramfs.img'
if [ ! -e $ISO_DIR/boot/vmlinuz-$KERNEL_VERSION ];then
    cp /boot/vmlinuz-$KERNEL_VERSION $ISO_DIR/boot/
fi
if [ ! -e $ISO_DIR/boot/initrd.img-$KERNEL_VERSION ];then
    cp /boot/initrd.img-$KERNEL_VERSION $ISO_DIR/boot/
fi

# >>>ROOTFS DIR<<<
if [ ! -e $ISO_DIR/rootfs ];then
    mkdir $ISO_DIR/rootfs -p
    mount /dev/mapper/loop200p3 $ISO_DIR/rootfs
    echo "mount /dev/mapper/loop200p3 to $ISO_DIR/rootfs" >> log.txt 
else
    if ! mountpoint -q $ISO_DIR/rootfs ;then
        mount /dev/mapper/loop200p3 $ISO_DIR/rootfs
        echo mount /dev/mapper/loop200p3 to $ISO_DIR/rootfs >> log.txt 
    fi
fi
#systemd install
#cd $HAOOS_DIR/systemd
#if [ ! -e $HAOOS_DIR/systemd/build/systemd ];then
#	./configure
#	make -j32
#fi
#export DESTDIR=$HAOOS_DIR/iso/rootfs
#make install
#cd -

#debootstrap make install the file system
if [ ! -e $ISO_DIR/rootfs/sbin/init ];then
	echo "rootfs not have debian file system, try to build rootfs ......"
	debootstrap stable $ISO_DIR/rootfs http://ftp2.cn.debian.org/debian/
	if [ ! -e $ISO_DIR/rootfs/boot/EFI ];then
		cp $ISO_DIR/grub/* $ISO_DIR/rootfs/boot/ -a
	fi
	if [ ! -e $ISO_DIR/rootfs/boot/vmlinuz-$(`uname -r`) ];then
		cp $ISO_DIR/boot/* $ISO_DIR/rootfs/boot/ -a
	fi
fi

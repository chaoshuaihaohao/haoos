#!/bin/bash
#install depends packets
apt install debootstrap kpartx qemu-kvm
#edk2 depends
apt install acpica-tools nasm libx11-dev libxext-dev
#grub depends
sudo apt install libdevmapper-dev fonts-dejavu libfuse-dev ttf-dejavu libzfslinux-dev liblzma-dev flex bison


HAOOS_DIR=/home/uos/Backup/github/haoos
ISO_DIR=/home/uos/Backup/github/haoos/iso
SCRIPTS_DIR=/home/uos/Backup/github/haoos/iso/scripts
KERNEL_VERSION=`uname -r`

echo "start" > log.txt
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
if [ ! -e $HAOOS_DIR/grub2/grub-install ];then
    make -C $HAOOS_DIR/grub2 -j32
fi

if [ ! -e $ISO_DIR/grub/EFI/grub/grubx64.efi ];then
echo "$HAOOS_DIR/grub2/grub-install \
    --boot-directory=$HAOOS_DIR/iso/grub \
    --efi-directory=$HAOOS_DIR/iso/grub \
    --directory=/usr/lib/grub/x86_64-efi /dev/mapper/loop200p1" >> log.txt 
$HAOOS_DIR/grub2/grub-install \
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
	debootstrap stable $ISO_DIR/rootfs https://www.debian.org/mirror/list
	echo "build rootfs successed"
	if [ ! -e $ISO_DIR/rootfs/boot/EFI ];then
		cp $ISO_DIR/grub/* $ISO_DIR/rootfs/boot/ -a
	fi
	if [ ! -e $ISO_DIR/rootfs/boot/vmlinuz-$(`uname -r`) ];then
		cp $ISO_DIR/boot/* $ISO_DIR/rootfs/boot/ -a
	fi
fi

#[200~No protocol specified
#Unable to init server: Could not connect: Connection refused
#gtk initialization failed
#]


#qemu start haoos systemd
qemu-img convert -O qcow2 $ISO_DIR/haoos.img $ISO_DIR/qemu-haoos.img
echo "qemu-img convert -O qcow2 $ISO_DIR/haoos.img $ISO_DIR/qemu-haoos.img" >> log.txt 
echo "qemu-system-x86_64 -m 1G \
    -bios $HAOOS_DIR/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd \
    -hda $ISO_DIR/qemu-haoos.img" >> log.txt 
qemu-system-x86_64 -m 1G \
    -bios $HAOOS_DIR/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd \
    -hda $ISO_DIR/qemu-haoos.img


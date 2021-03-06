#HAOOS_DIR=$(DESTDIR)
HAOOS_DIR=/home/uos/Backup/github/haoos
SUB_DIR=/home/uos/Backup/github/haoos/submodules
ISO_DIR=$(HAOOS_DIR)/iso
SCRIPTS_DIR=$(HAOOS_DIR)/iso/scripts
BOOT_DIR=$(HAOOS_DIR)/iso/boot
GRUB_DIR=$(HAOOS_DIR)/iso/grub
GRUB_CFG=$(GRUB_DIR)/grub/grub.cfg
ROOTFS_DIR=$(HAOOS_DIR)/iso/rootfs
export EDK_TOOLS_PATH=$(SUB_DIR)/edk2/BaseTools
export WORKSPACE=$(SUB_DIR)/edk2
export CONF_PATH=$(SUB_DIR)/edk2/Conf
KERNEL_VERSION=`uname -r`
DISK-UUID=$(shell ls -l /dev/disk/by-uuid/ | grep dm-2 | awk -F " " '{print $$9}')
VMLINUZ=vmlinuz-$(KERNEL_VERSION)
INITRD=initrd.img-$(KERNEL_VERSION)

depends:
	#install depends packets
	sudo apt install -y debootstrap kpartx qemu-kvm
	#edk2 depends
	sudo apt install -y acpica-tools nasm libx11-dev libxext-dev
	#grub depends
	sudo apt install -y libdevmapper-dev fonts-dejavu libfuse-dev \
		ttf-dejavu libzfslinux-dev liblzma-dev flex bison 

edk2:
	cd $(WORKSPACE)
	make -C $(WORKSPACE)/BaseTools -j32
	source edksetup.sh
	build -p EmulatorPkg/EmulatorPkg.dsc -a X64 -t GCC5
	cd -

grub:


filesystem:
	sudo debootstrap stable $(ROOTFS_DIR) http://deb.debian.org/debian


grub_cfg:
	sudo cp $(HAOOS_DIR)/scripts/grub.cfg $(ISO_DIR)/grub/grub/
	#ls -l /dev/disk/by-uuid/ | grep dm-2 | awk -F " " '{print $9}'
	echo $(DISK-UUID)
	sudo sed -i "s/DISK-UUID/$(DISK-UUID)/g" $(GRUB_CFG)
	sudo sed -i "s/VMLINUZ/$(VMLINUZ)/g" $(GRUB_CFG)
	sudo sed -i "s/INITRD/$(INITRD)/g" $(GRUB_CFG)


run:
	make grub_cfg
	sudo qemu-img convert -O qcow2 $(ISO_DIR)/haoos.img $(ISO_DIR)/qemu-haoos.img
	sudo qemu-system-x86_64 -m 1G -smp 4 -machine accel=kvm \
		-bios $(SUB_DIR)/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd \
		-hda $(ISO_DIR)/qemu-haoos.img \
		-netdev bridge,br=br0,id=n1 -device virtio-net,netdev=n1
	#	-boot menu=on
	#	-nographic
clean:
	make -C linux clean
	#make -C edk2 clean
	make -C grub2 clean
	make -C busybox clean
	- rm log.txt
	cd $(ISO_DIR)
	rm -r boot  dev  etc  home  lib  lib64 media  mnt  opt  proc  root  run  srv  sys  tmp  usr  var
	cd -

umount:
	sudo umount $(BOOT_DIR)
	sudo umount $(GRUB_DIR)
	sudo umount $(ROOTFS_DIR)

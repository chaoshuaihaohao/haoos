2020/12/16

	1)修改grub.cfg文件,在linux参数中添加modprobe.blacklist=floppy禁用floppy模块,
	解决报错:
	floppy: error 10 while reading block 0
	blk_update_request:I/O error,dev fd0,sector 0 op 0x0:(READ) flags 0x0 phy_seg 1 prio class 0
	
	2)通过在主机中,修改/etc/initramfs-tools/initramfs.conf文件添加RESUME=none,使用
	mkinitramfs  -o initrd.img-`uname -r`  -v命令重新制作initrd.img文件并替换到/boot目录下,
	解决启动刷屏耗时超30秒问题:
	Begin: Running /scripts/local-block ... done

	3)qemu启动虚拟机命令行优化
	qemu命令行添加 -smp 4 -machine accel=kvm,内核启动耗时缩减至5秒内,提高巨大.

2020/12/20
	
	1)更改debian仓库路径为国内源http://ftp2.cn.debian.org/debian/,可以在网址https://www.debian.org/mirror/list
	查看到debian的各种镜像网站。这极大的提高了debootstrap创建文件系统的速度.
	2)qemu命令行添加"-netdev user,id=vmnic,smb=/",解决了UEFI在>>>
	BdsDxe: failed to load Boot0001 "UEFI QEMU DVD-ROM QM00003 " from PciRoot(0x0)/Pci(0x1,0x1)/Ata(Secondary,Master,0x0): Not Found
	BdsDxe: failed to load Boot0002 "UEFI QEMU HARDDISK QM00001 " from PciRoot(0x0)/Pci(0x1,0x1)/Ata(Primary,Master,0x0): Not Found
	<<<界面停留太久的问题,现在启动后可以立刻进入UEFI shell界面.

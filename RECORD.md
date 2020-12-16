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

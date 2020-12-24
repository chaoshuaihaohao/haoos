How to Install

git submodule update --init edk2
git submodule update --init grub2
编译edk2和grub2模块
============================================================
make depends
sudo su
export DESTDIR=<the path of haoos>
./run.sh
chroot rootfs
#添加账户
adduser haoos
passwd haoos

make
make run
============================================================




edk2
UEFI of haoos
============================================================
build edk2
============================================================
git clone https://github.com/tianocore/edk2.git
cd edk2
git submodule update --init
export WORKSPACE=<the path of edk2>
export EDK_TOOLS_PATH=<the path of edk2>/BaseTools
export CONF_PATH=<the path of edk2>/Conf
sudo apt install acpica-tools nasm libx11-dev libxext-dev

#编译Basetools
make -C $WORKSPACE/BaseTools -j32
source edksetup.sh
build -p EmulatorPkg/EmulatorPkg.dsc -a X64 -t GCC5
build -p OvmfPkg/OvmfPkgX64.dsc -a X64 -t GCC5




grub2
bootloader of haoos
下载grub源码包

git clone https://git.savannah.gnu.org/git/grub.git
./bootstrap
./configure

安装依赖包：
sudo apt install libdevmapper-dev fonts-dejavu libfuse-dev ttf-dejavu libzfslinux-dev liblzma-dev flex bison

编译：
make

initramfs-tools
initrd制作工具,用于制作initramfs.img.详情参见https://wiki.debian.org/initramfs-tools


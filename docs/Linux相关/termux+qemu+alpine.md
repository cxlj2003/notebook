# 环境准备

- windows电脑+scrcpy软件+vncviewer
- 安卓手机+数据线+termux软件 
- alpine-3.20 ARM版和X86_64版ISO镜像
# 1.安卓手机通过USB连接电脑
## 1.1 手机上打开USB调试

## 1.2 通过scrcpy软件控制手机
## 1.3 在手机上安装termux软件
# 2. 在termux终端下的操作
## 2.1 开启termux文件管理权限

执行以下命令并在手机上确认；
```
termux-setup-storage
```
## 2.1 更换软件包的源并升级系统

执行更改软件源的命令，如下：
```
termux-change-repo
```
选择Mirror-Group → Mirrors in Chinese Mailand；
```
pkg update &&pkg upgrade -y
```
## 2.2 安装openssh等必要软件

```
pkg install openssh vim wget lrzsz -y
```
启动ssh服务并查看ssh的监听端口,默认为8022
```
sshd 
ss -lnp | grep sshd
cat <EOF > ~/.bashrc
sshd
EOF
```
## 2.3 查看用户名并配置密码

使用以下命令查看当前用户名
```
whoami
```
使用以下命令配置当前用户的密码
```
passwd
```
## 2.4 通过ssh登录termux

```
ssh u0_a180@198.19.201.1 -p 8022
```
## 2.5 安装qemu

```
pkg install qemu-common qemu-system-x86-64 qemu-system-aarch64 qemu-utils -y
```
# 3. 运行X86_64虚机(速度很慢)
## 3.1 安装脚本

```
if [ ! -e ~/qemu/x86_64 ];then
	mkdir -p ~/qemu/x86_64
fi
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.3-x86_64.iso
qemu-img create -f qcow2 ~/qemu/x86_64/alpine_3.20_x86_64.img 10G
qemu-system-x86_64 \
-hda ~/qemu/x86_64/alpine_3.20_x86_64.img \
-cdrom ~/qemu/x86_64/alpine-virt-3.20.3-x86_64.iso \
-m 2048 \
-netdev user,id=user.0 \
-device e1000,netdev=user.0 \
-vga vmware \
-display vnc=:10 > /dev/null 2> /dev/null &
```
使用vncviewer连接5910,使用root用户登录，密码为空，使用以下命令安装操作系统
```
cat <<EOF > /etc/network/interfaces
auto lo  
iface lo inet loopback  
auto eth0  
iface eth0 inet dhcp
EOF
/etc/init.d/networking restart
setup-alpine
```
## 3.2 运行脚本

```
cat <<EOF > ~/.bashrc
sshd
nohup qemu-system-x86_64 -hda ~/qemu/x86_64/alpine_3.20_x86_64.img -boot c -m 1024 -netdev user,id=nde1,hostfwd=tcp::2222-:22 -device e1000,netdev=nde1,id=d-net1 -vnc :10 & >/dev/null
EOF
```
# 4. 运行ARM虚机
## 4.1 安装脚本

```
if [ ! -e ~/qemu/aarch64 ];then
	mkdir -p ~/qemu/aarch64
fi
wget -P ~/qemu/aarch64 https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-virt-3.20.3-aarch64.iso
wget -P ~/qemu/aarch64 http://releases.linaro.org/components/kernel/uefi-linaro/16.02/release/qemu64/QEMU_EFI.fd
qemu-img create -f qcow2 ~/qemu/aarch64/alpine_3.20_aarch64.img 10G
cd ~/qemu/aarch64
qemu-system-aarch64 \
-m 4096 \
-cpu cortex-a57 -smp 4 \
-M virt \
-bios QEMU_EFI.fd \
-nographic \
-drive if=none,file=alpine-virt-3.20.3-aarch64.iso,id=cdrom,media=cdrom -device virtio-scsi-device -device scsi-cd,drive=cdrom \
-drive if=none,file=alpine_3.20_aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 
```
使用root用户登录，密码为空，使用以下命令安装操作系统
```
cat <<EOF > /etc/network/interfaces
auto lo  
iface lo inet loopback  
auto eth0  
iface eth0 inet dhcp
EOF
/etc/init.d/networking restart
setup-alpine
```
安装选项配置如下:
```
 ALPINE LINUX INSTALL
----------------------

 Hostname
----------
Enter system hostname (fully qualified form, e.g. 'foo.example.org') [localhost] 
Which one do you want to initialize? (or '?' or 'done') [eth0]
Ip address for eth0? (or 'dhcp', 'none', '?') [dhcp]
Do you want to do any manual network configuration? (y/n) [n] 
Do you want to do any manual network configuration? (y/n) [n] 

udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 10.0.2.15, server 10.0.2.2
udhcpc: lease of 10.0.2.15 obtained from 10.0.2.2, lease time 86400

 Root Password
---------------
Changing password for root
New password: 
Retype password: 
passwd: password for root changed by root

 Timezone
----------
Africa/            Egypt              Iran               Poland
America/           Eire               Israel             Portugal
Antarctica/        Etc/               Jamaica            ROC
Arctic/            Europe/            Japan              ROK
Asia/              Factory            Kwajalein          Singapore
Atlantic/          GB                 Libya              Turkey
Australia/         GB-Eire            MET                UCT
Brazil/            GMT                MST                US/
CET                GMT+0              MST7MDT            UTC
CST6CDT            GMT-0              Mexico/            Universal
Canada/            GMT0               NZ                 W-SU
Chile/             Greenwich          NZ-CHAT            WET
Cuba               HST                Navajo             Zulu
EET                Hongkong           PRC                leap-seconds.list
EST                Iceland            PST8PDT            posixrules
EST5EDT            Indian/            Pacific/

Which timezone are you in? [UTC] Hongkong

 * Seeding random number generator ...
 * Saving 256 bits of creditable seed for next boot
 [ ok ]
 * Starting busybox crond ...
 [ ok ]

 Proxy
-------
HTTP/FTP proxy URL? (e.g. 'http://proxy:8080', or 'none') [none] 

 Network Time Protocol
-----------------------
Thu Sep 19 20:46:52 HKT 2024
Which NTP client to run? ('busybox', 'openntpd', 'chrony' or 'none') [chrony] 
 * service chronyd added to runlevel default
 * Caching service dependencies ...
 [ ok ]
 * Starting chronyd ...
 [ ok ]

 APK Mirror
------------
 (f)    Find and use fastest mirror
 (s)    Show mirrorlist
 (r)    Use random mirror
 (e)    Edit /etc/apk/repositories with text editor
 (c)    Community repo enable
 (skip) Skip setting up apk repositories

Enter mirror number or URL: [1] 15

Added mirror mirrors.ustc.edu.cn
Updating repository indexes... done.

 User
------
Setup a user? (enter a lower-case loginname, or 'no') [no] 
Which ssh server? ('openssh', 'dropbear' or 'none') [openssh] 
Allow root ssh login? ('?' for help) [prohibit-password] yes
Enter ssh key or URL for root (or 'none') [none] 
 * service sshd added to runlevel default
 * Caching service dependencies ...
 [ ok ]
ssh-keygen: generating new host keys: RSA ECDSA ED25519 
 * Starting sshd ...
 [ ok ]

 Disk & Install
----------------
Available disks are:
  vda   (10.7 GB 0x554d4551 )

Which disk(s) would you like to use? (or '?' for help or 'none') [none] vda

The following disk is selected:
  vda   (10.7 GB 0x554d4551 )

How would you like to use it? ('sys', 'data', 'crypt', 'lvm' or '?' for help) [?] lvm

The following disk is selected (with LVM):
  vda   (10.7 GB 0x554d4551 )

How would you like to use it? ('sys', 'data' or '?' for help) [?] sys

WARNING: The following disk(s) will be erased:
  vda   (10.7 GB 0x554d4551 )

WARNING: Erase the above disk(s) and continue? (y/n) [n] y
Creating file systems...
mkfs.fat 4.2 (2021-01-31)
  Physical volume "/dev/vda2" successfully created.
  Logical volume "lv_swap" created.
  Logical volume "lv_root" created.
 * service lvm added to runlevel boot
Installing system on /dev/vg0/lv_root:
Installing for arm64-efi platform.
Installation finished. No error reported.
100% ████████████████████████████████████████████==> initramfs: creating /boot/initramfs-virt for 6.6.51-0-virt
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-virt
Found initrd image: /boot/initramfs-virt
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

Installation is complete. Please reboot.

```
运行`poweroff`关闭虚机
## 4.2 运行脚本

```
cat <<EOF > ~/qemu/aarch64/run.sh
qemu-system-aarch64 \
-m 2048 \
-cpu cortex-a57 -smp 2 \
-M virt \
-bios QEMU_EFI.fd \
-nographic \
-device virtio-scsi-device \
-drive if=none,file=alpine_3.20_aarch64.img,index=0,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev user,id=net0,hostfwd=tcp::2222-:22 -device virtio-net-device,netdev=net0
EOF
```

```
cd  ~/qemu/aarch64 && bash run.sh
```
# ~~5. 使用KVM运行ARM虚机~~
## ~~5.1 termux启用kvm~~

```
pkg install texinfo -y
info kvm
```

```
pkg install termux-apt-repo build-essential busybox -y
```

```
pkg install linux-source
```

```
cd /data/data/com.termux/files/usr/src/
git clone https://github.com/aosp-mirror/platform_frameworks_kitkat.git
```

```
cd platform-frameworks-kernel
make defconfig
make modules
cp arch/arm/boot/zImage /data/data/com.termux/files/usr/
cp arch/arm/boot/dts/bcm2708-rpi.dtb /data/data/com.termux/files/usr/
```

```
pkg install qemu-user-static
```

```

```
## ~~5.2 使用KVM运行~~

```

```
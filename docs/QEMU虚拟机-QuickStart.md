# 环境准备

- VMWare Workstation软件
- [Ubuntu24.04lts X86_64 iso镜像](https://releases.ubuntu.com/24.04/ubuntu-24.04.1-live-server-amd64.iso)
- [Alpine3.20 ARM iso镜像](https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-virt-3.20.2-aarch64.iso)
- [Ubuntu24.04lts ARM IMG镜像](https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img)
- [Debian12 X86_64 qcow2镜像](https://gemmei.ftp.acc.umu.se/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2)

> [!NOTE] 已略过步骤
> - VMWare Workstation软件安装
> -  在VMWare Workstation中安装Ubuntu24.04LTS

# 1. 安装QEMU
## 1.1. Ubuntu 24.04LTS

```
apt -y install qemu-system qemu-utils
```
## 1.2. Windows 11

[下载地址](https://qemu.weilnetz.de/w64/2024/qemu-w64-setup-20240903.exe)
# 2. 网络配置（桥接网络）
## 2.1. Ubuntu  24.04LTS
- 将物理网络桥接至br0网桥；

```
cat <<EOF > /etc/netplan/ens32.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens32:
      dhcp4: no
  bridges:
    br0:
      dhcp4: no
      addresses:
        - 198.19.201.119/24
      routes:
        - to: default
          via: 198.19.201.254
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
      interfaces:
        - ens32
EOF
chmod 600 /etc/netplan/ens32.yaml
```

> [!NOTE] 注:
> 网络配置文件位于/etc/netplan目录下,扩展名为.yaml
> 本例中的配置文件以系统中物理网卡名称命名ens32.yaml

- 在QEMU配置文件中添加允许桥接的网桥并重启服务器。

```
if [ ! -e /etc/qemu ];then
	mkdir /etc/qemu
fi
echo 'allow br0' > /etc/qemu/bridge.conf
reboot
```
## 2.2. Windows 11

# 3. 使用ISO镜像安装和运行Alpine3.20
## 3.1. 安装脚本

```
if [ ! -e /data/alpine ];then
	mkdir -p /data/alpine
fi
cd /data/alpine
wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-virt-3.20.2-aarch64.iso
truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
qemu-img create system.img 10G
qemu-system-aarch64 \
-m 4096 \
-cpu cortex-a57 -smp 4 \
-M virt \
-bios efi.img \
-nographic \
-drive if=none,file=alpine-virt-3.20.2-aarch64.iso,id=cdrom,media=cdrom -device virtio-scsi-device -device scsi-cd,drive=cdrom \
-drive if=none,file=system.img,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0
```
## 3.2.运行脚本

```
cat <<EOF > /data/alpine/run.sh
qemu-system-aarch64 \
-m 2048 \
-cpu cortex-a57 -smp 2 \
-M virt \
-bios efi.img \
-nographic \
-device virtio-scsi-device \
-drive if=none,file=system.img,format=raw,index=0,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0
EOF
```

```
bash /data/alpine/run.sh
```
# 4. 使用raw格式的云镜像运行Ubuntu24.04LTS

```
if [ ! -e /data/ubuntu2404 ];then
	mkdir -p /data/ubuntu2404
fi
cd /data/ubuntu2404
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img
truncate -s 64m varstore.img
truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
cat <<EOF >run.sh
qemu-system-aarch64 \
-m 2048 \
-cpu max \
-M virt \
-nographic \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img \
-drive if=none,file=ubuntu-24.04-server-cloudimg-arm64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0
EOF
```

```
bash /data/ubuntu2404/run.sh
```
# 5. 使用qcow2格式的云镜像运行Debian12

```
if [ ! -e /data/debian12 ];then
	mkdir -p /data/debian12
fi
cd /data/debian12
cat <<EOF >/data/debian12/run.sh
qemu-system-x86_64 \
-m 2048 \
-cpu max \
-M virt \
-nographic \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img \
-drive if=none,file=ubuntu-24.04-server-cloudimg-arm64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0
EOF
```

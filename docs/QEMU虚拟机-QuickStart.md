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


```
apt -y install qemu-system qemu-utils
```

# 2. 网络配置（桥接网络）

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
- 生成随机MAC
```
cat <<EOF > /usr/local/bin/macgen
#!/usr/bin/python3
import random
def randomMAC():
    return [ 0x00, 0x16, 0x3e,
            random.randint(0x00, 0x7f),
            random.randint(0x00, 0xff),
            random.randint(0x00, 0xff) ]

def MACprettyprint(mac):
    return ':'.join(map(lambda x: "%02x" % x, mac))

if __name__ == '__main__':
    print(MACprettyprint(randomMAC()))
EOF
chmod +x /usr/local/bin/macgen
```

# 3. 使用ISO镜像运行Alpine3.20
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
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0,mac=`macgen`
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
-drive if=none,file=system.img,index=0,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0,mac=`macgen`
EOF
```

```
bash /data/alpine/run.sh
```
# 4. 使用CloudIMG运行ARM64虚机
## 4.1. Ubuntu24.04 IMG

```
if [ ! -e /data/ubuntu2404 ];then
	mkdir -p /data/ubuntu2404
fi
cd /data/ubuntu2404
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img
#wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.raw
apt -y install guestfs-tools
virt-customize -a ubuntu-24.04-server-cloudimg-arm64.img --root-password password:123456
truncate -s 64m varstore.img
truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
cat <<EOF > /data/ubuntu2404/run.sh
qemu-system-aarch64 \
-m 2048 \
-cpu cortex-a57 -smp 4 \
-M virt \
-nographic \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img \
-drive if=none,file=ubuntu-24.04-server-cloudimg-arm64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0,mac=`macgen`
EOF
```

```
bash /data/ubuntu2404/run.sh
```
## 4.2 Debian12 RAW

```
if [ ! -e /data/debian12arm ];then
	mkdir -p /data/debian12arm
fi
cd /data/debian12arm
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.raw
apt -y install guestfs-tools
virt-customize -a debian-12-nocloud-arm64.raw --root-password password:123456
truncate -s 64m varstore.img
truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
cat <<EOF > /data/debian12arm/run.sh
qemu-system-aarch64 \
-m 4096 \
-cpu cortex-a57 -smp 4 \
-M virt \
-nographic \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img \
-drive if=none,file=debian-12-nocloud-arm64.raw,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0,mac=`macgen`
EOF
```

```
bash /data/debian12arm/run.sh
```
## 4.3 Debian12 qcow2

```
if [ ! -e /data/debian12arm-qcow2 ];then
	mkdir -p /data/debian12arm-qcow2
fi
cd /data/debian12arm-qcow2
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2
apt -y install guestfs-tools
virt-customize -a debian-12-generic-arm64.qcow2 --root-password password:123456
truncate -s 64m varstore.img
truncate -s 64m efi.img
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=efi.img conv=notrunc
cat <<EOF > /data/debian12arm-qcow2/run.sh
qemu-system-aarch64 \
-m 4096 \
-cpu cortex-a57 -smp 4 \
-M virt \
-nographic \
-drive if=pflash,format=raw,file=efi.img,readonly=on \
-drive if=pflash,format=raw,file=varstore.img \
-drive if=none,file=debian-12-generic-arm64.qcow2,id=hd0 -device virtio-blk-device,drive=hd0 \
-netdev bridge,br=br0,id=net0 -device virtio-net-device,netdev=net0,mac=`macgen`
EOF
```

```
bash /data/debian12arm-qcow2/run.sh
```
# 5. 使用CloudIMG运行X86_64虚机

```
if [ ! -e /data/debian12 ];then
	mkdir -p /data/debian12
fi
cd /data/debian12
wget https://gemmei.ftp.acc.umu.se/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2
apt -y install guestfs-tools
virt-customize -a debian-12-nocloud-amd64.qcow2 --root-password password:123456
cat <<EOF > /data/debian12/run.sh
qemu-system-x86_64 \
-smp 2 \
-m 2048 \
-nographic \
-boot c \
-hda debian-12-nocloud-amd64.qcow2 \
-netdev bridge,br=br0,id=net0 -device rtl8139,netdev=net0,mac=`macgen`
EOF
```

```
bash /data/debian12/run.sh
```

---


> 相关文档
> https://wiki.qemu.org/Documentation
> 

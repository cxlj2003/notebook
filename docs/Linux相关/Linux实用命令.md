# 1. 修改区域语言

```
#查看当前配置
localectl status 
#查看可用选项
localectl list-locales
#设置成英文
localectl set-locale en_US.UTF-8
```
# 2. 修改时区
## 2.1 timedatectl
```
#查看时区
timedatectl status
#查看可用选项
timedatectl list-timezones
#设置时区为Asia/Shanghai
timedatectl set-timezone Asia/Shanghai
```
## 2.2 tzselect

```
tzselect
#选择Asia/Shanghai
```

## 2.3 链接/etc/localtime

```
rm -rf /etc/localtime
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```
## 2.4 date 格式显示

```
date "+%Y-%m-%d"
date "+%m%d%y"
#年 %Y
#年后两位 %y
#月 %m
#月（英文代码） %h
#日 %d
#时 %H
#分 %M
#秒 %S
```

## 2.5 修改Grub启动延时

```
sed -i "s/set timeout=.*/set timeout=2/g" /boot/grub/grub.cfg
```
# 3.`ansible`

```
apt -y install ansible
mkdir -p /etc/ansible
cat << 'EOF' > /etc/ansible/hosts
[admin]
192.168.100.1
192.168.100.2
[test]
192.168.100.1
192.168.100.2
[test2:children]
admin
test
EOF
```

获取帮助
```
ansible-doc apt
ansible-doc -l
```

常用命令及模块
```
ansible all -m ping
ansible all -m command -a "/sbin/reboot -t now"
ansible all -m shell -a "bash /opt/baseconfig.sh"
ansible 'all:!admin' -m service -a "name=httpd state=started"
ansible 'all:!admin' -m synchronize -a "src=/opt dest=/"
```
# 4. 内核模块

```
#查看模块
lsmod 
#加载模块
modprobe <modname>
#卸载模块
rmmod <modmanme>
#开机加载模块
cat <<EOF > /etc/modules-load.d/pre-load.conf
tun
EOF
```

# 5. 检查脚本语法

```
bash -n script.sh
bash -ex script.sh
```

# 6.`iproute2`

```
ip add add 198.19.201.130/24 dev ens32
ip link set ens32 up
ip route add default via 198.19.201.254
```

# 7.`nmcli`

类Debian系统使用`apt install cockpit-networkmanager`命令安装

```
nmcli conn sh #查看网络连接 
nmcli conn add con-name ens32 if-name ens32 type ethernet #新增网卡连接配置
nmcli conn mod ens32 ipv4.add 198.19.201.130/24 #配置IPV4地址
nmcli conn mod ens32 ipv4.gate 198.19.201.254 #配置默认网关
nmcli conn mod ens32 ipv4.dns 8.8.8.8,114.114.114.114 #配置DNS
nmcli conn mod ens32 ipv4.meth man #手动配置IP
nmcli conn mod ens32 autoconnect yes #配置开机自动连接网络
nmcli down ens32 && nmcli up ens32 #重启网卡


nmcli con add type bond con-name bond1 ifname bond1 mode 802.3ad #创建lacp-bond
nmcli con mod bond1 autoconnect y #开机自动连接
nmcli con add type bond-slave ifname p4p2 master bond1 #添加物理接口1
nmcli con add type bond-slave ifname p6p2 master bond1 #添加物理接口2
nmcli con mod bond1 ipv4.add 100.120.0.1/24 #配置IP


nmcli conn modify bond1 +ipv4.routes "100.201.3.117/32 100.120.0.254" #添加静态路由
nmcli conn down bond1 && nmcli conn up bond1 #重启网卡

nmcli conn edit # 交互式

nmtui # 图形化

# 无线网络
nmcli radio wifi on
nmcli dev wifi list


```

```
netplan get
netplan set bonds.bond1.parameters.mode=active-backup
```

```
##The default is `balance-rr` (round robin). Possible values are `balance-rr`, `active-backup`, `balance-xor`, `broadcast`, `802.3ad`, `balance-tlb` and `balance-alb`. For Open vSwitch `active-backup` and the additional modes `balance-tcp` and `balance-slb` are supported.
```
# 8.用户和组

```
# /etc/passwd
# /etc/group
#查看所有用户组信息
cat /etc/passwd | cut -d: -f1 |xargs id 
groupadd -g [gid] [groupname] #创建指定gid的组
useradd -u [uid] -g [groupname] [username] #创建指定uid的用户并添加至相应的组(已存在)
userdel [username] #删除用户
userdel -r [username] #删除用户及主目录
```

示例
```
groupadd -g 1314 orclgrp
useradd -u 1314 -g orclgrp orcl
```

# 9.软件包管理

## 9.1`yum/dnf`
```
yum list installed #查看已安装的软件包
yum list |egrep '^http' #查找已http开头的软件包
yum info [packagename] |grep Version |uniq #查找软件的版本
```
示例
```
yum info ceph |grep Version |uniq
```
运行结果
```
Version      : 18.2.2
```

## 9.2`apt`
```
echo 'DEBIAN_FRONTEND=noninteractive' >> /etc/profile
source /etc/profile
apt list --installed #查看已安装的软件包
apt list |egrep '^http' #查找已http开头的软件包
apt show [packagename] |grep Version |uniq #查找软件的版本
```
示例
```
apt show ceph |grep Version |uniq
```
运行结果
```
WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Version: 19.2.0-0ubuntu0.24.04.1
```

## 9.3编译环境安装

```
yum groupinstall 'Development Tools' -y
```

```
apt install bulid-essential -y
```

# 10.`reposync`

```
yum repolist
```

实例1：基本的仓库同步  
同步一个指定的仓库至本地目录。  
  
```
reposync --repoid=your-repo-id -p=/path/to/local/dir 
```
实例2：同步最新的包  
只下载最新版本的包。  
  
```
reposync --newest-only --repoid=your-repo-id -p=/path/to/local/dir 
```` 
实例3：同步指定架构的包  
同步指定架构（如x86_64）的包。  
  
```
reposync --arch=x86_64 --repoid=your-repo-id -p=/path/to/local/dir
``` 
实例4：删除本地不存在于远程的包  
删除本地仓库中不存在于远程仓库的包。  
  
```
reposync --delete --repoid=your-repo-id -p=/path/to/local/dir
```  
实例5：下载仓库元数据  
同步包含元数据的完整仓库。  
  
```
reposync --download-metadata --repoid=your-repo-id -p=/path/to/local/dir
```
实例6：启用YUM插件  
在同步时启用YUM插件。  
  
```
reposync --plugins --repoid=your-repo-id -p=/path/to/local/dir
``` 
实例7：输出下载URL而不实际下载  
仅输出包的URL，不下载包。  
  
```
reposync --urls --repoid=your-repo-id
```
实例8：进行GPG签名检查  
在同步过程中进行GPG签名检查。  
  
```
reposync --gpgcheck --repoid=your-repo-id -p=/path/to/local/dir
``` 

# 11.磁盘操作

## 11.1基础操作
### 1)扫描磁盘
```
for x in `ls /sys/class/scsi_host`; do echo "- - -" > /sys/class/scsi_host/$x/scan; done
```
### 2)查看磁盘
```
lsblk
```
## 11.2逻辑卷`lvm2`
### 1)安装lvm2
```
yum install lvm2 -y # Fedora系列
apt install lvm2 -y # Debian系列
```
### 2)物理卷
```
# 创建物理卷,物理卷可以是分区或整块磁盘
pvcreate /dev/sdb1
pvcreate /dev/sdb
# 查看物理卷
pvdisplay
# 调整物理卷,用于物理磁盘扩容
pvresize /dev/sdb
```

### 3)卷组
```
# 使用指定物理卷创建卷组
vgcreate vg0 /dev/sdb /dev/sdc
# 使用新物理卷扩容卷组
vgextend vg0 /dev/sdd
```

### 4)逻辑卷
```
# 创建逻辑卷
lvcreate -n lv0 -L 10G vg0
lvcreate -n lv0 -l +100%FREE vg0
# 扩容逻辑卷
lvextend -L 10G /dev/vg0/lv0
lvextend -l +100%FREE /dev/vg0/lv0
```

### 5)使用逻辑卷
#### 格式化
```
# 使用ext4格式化逻辑卷
mkfs.ext4 /dev/vg0/lv0
# 使用xfs格式化逻辑卷
mkfs.xfs /dev/vg0/lv0
```
#### 扩容文件系统
```
# 扩容ext4文件系统
resize2fs /dev/vg0/lv0
# 扩容xfs文件系统
xfs_growfs /dev/vg0/lv0
```

#### 挂载
```
# ext4格式
mkdir -p /mnt/vg0/lv0
echo /dev/vg0/lv0 /mnt/vg0/lv0 ext4 defaults 0 0 >> /etc/fstab
mount -a
# xfs格式
mkdir -p /mnt/vg0/lv0
echo /dev/vg0/lv0 /mnt/vg0/lv0 xfs defaults 0 0 >> /etc/fstab
mount -a
```
## 11.3FC多路径

### 1)查看HBA WWN
方法1:
```
cat /sys/class/fc_host/host*/port_name
```
方法2:
```
for x in `ls /sys/class/fc_host`; do more /sys/class/fc_host/$x/port_name; done
```
结果:
```
0x100000109b6040c4
0x100000109b6046c
```

### 2)查看WWID

```
cat /etc/multipath/wwids
```
结果:
```
# Multipath wwids, Version : 1.0
# NOTE: This file is automatically maintained by multipath and multipathd.
# You should not need to edit this file in normal circumstances.
#
# Valid WWIDs:
/3600000e00d2a0000002a07b600100000/
/3600000e00d2a0000002a07b600030000/
/3600000e00d2a0000002a07b600040000/
```

### 3)扫描FC磁盘

```

for x in `ls /sys/class/fc_host`; do echo "- - -" > /sys/class/scsi_host/$x/scan; done
```

### 4)修改多路径配置文件 

示例:
```
defaults {
        user_friendly_names yes
        find_multipaths yes
}
blacklist {
      devnode "^(ram|raw|loop|fd|md|dm-|sr|scd|st)[0-9]*"
      devnode "^(s|v|h)d[a-z]"
}

multipaths {
       multipath {
               wwid                    3600000e00d2a0000002a07b600100000
               alias                   lun0
               path_grouping_policy    multibus
               path_selector           "round-robin 0"
               failback                manual
               rr_weight               priorities
               no_path_retry           5
       }
       multipath {
               wwid                    3600000e00d2a0000002a07b600030000
               alias                   lun1
               path_grouping_policy    multibus
               path_selector           "round-robin 0"
               failback                manual
               rr_weight               priorities
               no_path_retry           5
       }
       
       multipath {
               wwid                    3600000e00d2a0000002a07b600040000
               alias                   lun2
               path_grouping_policy    multibus
               path_selector           "round-robin 0"
               failback                manual
               rr_weight               priorities
               no_path_retry           5
       }
       
}
devices {
       device {
               vendor                  "FUJITSU"
               product                 "AS5600"
               path_grouping_policy    multibus
               path_checker            readsector0
               path_selector           "round-robin 0"
               hardware_handler        "0"
               failback                15
               rr_weight               priorities
               no_path_retry           queue
       
}

```

### 5)重启服务并验证
```
systemctl restart multipathd
multipath -ll
```
结果:
```
lun2 (3600000e00d2a0000002a07b600040000) dm-6 FUJITSU ,ETERNUS_DXM     
size=800G features='1 queue_if_no_path' hwhandler='0' wp=rw
`-+- policy='round-robin 0' prio=30 status=active
  |- 14:0:0:2 sdj 8:144 active ready running
  |- 15:0:0:2 sdl 8:176 active ready running
  |- 14:0:1:2 sdk 8:160 active ready running
  `- 15:0:1:2 sdm 8:192 active ready running
lun1 (3600000e00d2a0000002a07b600030000) dm-5 FUJITSU ,ETERNUS_DXM     
size=200G features='1 queue_if_no_path' hwhandler='0' wp=rw
`-+- policy='round-robin 0' prio=30 status=active
  |- 14:0:0:1 sdf 8:80  active ready running
  |- 15:0:0:1 sdh 8:112 active ready running
  |- 14:0:1:1 sdg 8:96  active ready running
  `- 15:0:1:1 sdi 8:128 active ready running
lun0 (3600000e00d2a0000002a07b600100000) dm-2 FUJITSU ,ETERNUS_DXM     
size=1.0T features='1 queue_if_no_path' hwhandler='0' wp=rw
`-+- policy='round-robin 0' prio=30 status=active
  |- 14:0:0:0 sdb 8:16  active ready running
  |- 15:0:0:0 sdd 8:48  active ready running
  |- 14:0:1:0 sdc 8:32  active ready running
  `- 15:0:1:0 sde 8:64  active ready running
```

## 11.4iscsi存储

### 1)查看ISCSI IQN

```
cat /etc/iscsi/initiatorname.iscsi
```
结果:
```
## DO NOT EDIT OR REMOVE THIS FILE!
## If you remove this file, the iSCSI daemon will not start.
## If you change the InitiatorName, existing access control lists
## may reject this initiator.  The InitiatorName must be unique
## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
InitiatorName=iqn.2004-10.com.ubuntu:01:688cf580e02f
```

>[!NOTE]
>IQN格式
>iqn+.+年月+.+域名倒置+:+设备名称+:+接口名称
>例如:`iqn.2024.10.com.inspur:server01:iscsi01`

# 12.个性化配置

## 12.1 motd

openEluer
```
#动态配置文件 /etc/profile.d/
#配置文件 /etc/pam.d/sshd → /etc/motd
sed -i 's|session    optional     pam_motd.so|#session    optional     pam_motd.so|g' /etc/pam.d/sshd 
#配置文件sshd_config → /etc/issue.net
sed -i 's|Banner.*|#Banner None|g' /etc/ssh/sshd_config
sed -i 's|PrintMotd.*|PrintMotd no|g' /etc/ssh/sshd_config
sed -i '/PrintLastLog/d' /etc/ssh/sshd_config
echo 'PrintLastLog no' >> /etc/ssh/sshd_config
systemctl restart sshd
```

Debian
```
#动态配置文件/etc/update-motd.d/

#重新生成动态文件
rm -f /run/motd.dynamic && run-parts /etc/update-motd.d/
#配置文件 /etc/motd
```

Ubuntu
```
#动态配置文件/etc/update-motd.d/

#重新生成动态文件
rm -f /run/motd.dynamic && run-parts /etc/update-motd.d/
#配置文件 /etc/motd
```

Alpine
```
#配置文件 /etc/motd

```

## 12.2按键

```
# 笔记本电脑合上屏幕不待机
sed -i "s/#HandleLidSwitch=.*/HandleLidSwitch=ignore/g" /etc/systemd/logind.conf 
```
# 13.安全加固

## 13.1账户口令


### 1)屏蔽系统账户登录系统

```
usermod -L -s /sbin/nologin $systemaccount
```

### 2)限制使用su命令的帐户 /etc/pam.d/su

```
auth         required      pam_wheel.so use_uid
```

### 3)设置口令复杂度

口令复杂度通过/etc/pam.d/password-auth和/etc/pam.d/system-auth文件中的pam_pwquality.so和pam_pwhistory.so模块实现。用户可以通过修改这两个模块中的配置项修改口令复杂度。

在/etc/pam.d/password-auth和/etc/pam.d/system-auth文件中password配置项的前两行添加如下配置内容：
```
password    requisite     pam_pwquality.so minlen=8 minclass=3 enforce_for_root try_first_pass local_users_only retry=3 dcredit=0 ucredit=0 lcredit=0 ocredit=0 
password    required      pam_pwhistory.so use_authtok remember=5 enforce_for_root
```

|**配置项**|**说明**|
|---|---|
|minlen=8|口令长度至少包含8个字符|
|minclass=3|口令至少包含大写字母、小写字母、数字和特殊字符中的任意3种|
|ucredit=0|口令包含任意个大写字母|
|lcredit=0|口令包含任意个小写字母|
|dcredit=0|口令包含任意个数字|
|ocredit=0|口令包含任意个特殊字符|
|retry=3|每次修改最多可以尝试3次|
|enforce_for_root|本设置对root帐户同样有效|

|**配置项**|**说明**|
|---|---|
|remember=5|口令不能修改为过去5次使用过的旧口令|
|enforce_for_root|本设置对root帐户同样有效|

### 4)设置口令有效期

口令有效期的设置通过修改/etc/login.defs文件实现

|**加固项**|**加固项说明**|**建议加固**|**openEuler默认是否已加固为建议值**|
|---|---|---|---|
|PASS_MAX_DAYS|口令最大有效期|90|否|
|PASS_MIN_DAYS|两次修改口令的最小间隔时间|0|否|
|PASS_WARN_AGE|口令过期前开始提示天数|7|否|

>[!NOTE]
> login.defs是设置用户帐号限制的文件，可配置口令的最大过期天数、最大长度约束等。该文件里的配置对root用户无效。如果/etc/shadow文件里有相同的选项，则以/etc/shadow配置为准，即/etc/shadow的配置优先级高于/etc/login.defs。口令过期后用户重新登录时，提示口令过期并强制要求修改，不修改则无法进入系统。

### 5)设置口令的加密算法

口令的加密算法设置通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现，添加如下配置：

```
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok

```

### 6)登录失败超过三次后锁定

口令复杂度的设置通过修改/etc/pam.d/password-auth和/etc/pam.d/system-auth文件实现，设置口令的最大出错次数为3次，系统锁定后的解锁时间为300秒的配置如下：

```
auth        required      pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
auth        [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
auth        sufficient    pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
```

|**配置项**|**说明**|
|---|---|
|authfail|捕获用户登录失败的事件。|
|deny=3|用户连续登录失败次数超过3次即被锁定。|
|unlock_time=300|普通用户自动解锁时间为300秒（即5分钟）。|
|even_deny_root|同样限制root帐户。|
### 6)加固su命令

通过修改/etc/login.defs实现，配置如下：

```
ALWAYS_SET_PATH=yes
```

## 13.2授权认证

### 1)设置网络远程登录的警告信息

该设置可以通过修改/etc/issue.net文件的内容实现。将/etc/issue.net文件原有内容替换为如下信息（openEuler默认已设置）：

```
Authorized users only. All activities may be monitored and reported. 
```

### 2)禁止通过Ctrl+Alt+Del重启系统

删除两个ctrl-alt-del.target文件
```
rm -f /etc/systemd/system/ctrl-alt-del.target
rm -f /usr/lib/systemd/system/ctrl-alt-del.target
```

修改/etc/systemd/system.conf文件，将#CtrlAltDelBurstAction=reboot-force修改为CtrlAltDelBurstAction=none,重启systemd使配置生效。
```
sed -i 's|#CtrlAltDelBurstAction=reboot-force|CtrlAltDelBurstAction=none|g' /etc/systemd/system.conf
systemctl daemon-reexec
```

### 3)设置终端的自动退出时间

```
echo 'export TMOUT=900' >> /etc/profile && source /etc/profile
```

### 4)设置用户的默认umask值为077

在/etc/bashrc文件和/etc/profile.d/目录下的所有文件中加入“umask 0077”

```
echo 'umask 0077' >> /etc/bashrc
ls /etc/profile.d | xargs -i echo 'umask 0077' /etc/profile.d/{}
source /etc/bashrc
```

将/etc/bashrc文件和/etc/profile.d/目录下的所有文件的属主和属组修改为root

```
chown root:root /etc/bashrc
ls /etc/profile.d | xargs -i chown root:root /etc/profile.d/{}
```

### 5)设置GRUB2加密口令

生成加密口令
```
grub2-mkpasswd-pbkdf2
```

在grub.cfg中配置加密口令
```
set superusers="root"
password_pbkdf2 root grub.pbkdf2.sha512.10000.5A45748D892672FDA02DD3B6F7AE390AC6E6D532A600D4AC477D25C7D087644697D8A0894DFED9D86DC2A27F4E01D925C46417A225FC099C12DBD3D7D49A7425.2BD2F5BF4907DCC389CC5D165DB85CC3E2C94C8F9A30B01DACAA9CD552B731BA1DD3B7CC2C765704D55B8CD962D2AEF19A753CBE9B8464E2B1EB39A3BB4EAB08
```

>[!NOTE]
>不同模式下grub.cfg文件所在路径不同
>x86架构的UEFI模式下路径为/boot/efi/EFI/openEuler/grub.cfg
>legacy BIOS模式下路径/boot/grub2/grub.cfg
>aarch64架构下路径为/boot/efi/EFI/openEuler/grub.cfg。

### 6)安全单用户模式

该设置可以通过修改/etc/sysconfig/init文件内容实现。将SINGLE选项配置为SINGLE=/sbin/sulogin.

### 7)禁止交互式启动

该设置可以通过修改/etc/sysconfig/init文件内容实现。将PROMPT选项配置为PROMPT=no。

## 13.3系统服务

### 1)加固SSH服务

/etc/ssh/sshd_config

# 14.`iptalbes`和`nftables`

开启路由转发
```
echo net.ipv4.ip_forward=1 >>/etc/sysctl.conf
echo net.ipv6.conf.all.forwarding=1 >>/etc/sysctl.conf
sysctl -p /etc/sysctl.conf
```

# 15. 下载工具

## 15.1`axel`

```
wget https://github.com/axel-download-accelerator/axel/releases/download/v2.17.14/axel-2.17.14.tar.gz

tar -zxvf axel-2.17.14.tar.gz
cd axel-2.17.14
./configure --without-ssl
make && make install

ln -svf /usr/local/bin/axel /usr/bin/axel

```

## 15.2`curl`

## 15.3 `wget`
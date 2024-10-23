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
# 3. date 格式显示

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

```
示例
```

```

## 9.2`apt`
```

```
示例
```

```


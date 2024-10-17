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
```


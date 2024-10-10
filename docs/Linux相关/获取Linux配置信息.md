# 软件安装
Alpine
```
apk add pciutils lshw lsblk lsb-release dmidecode
```
CentOS
```
yum install redhat-lsb
```
# 1.CPU

```
#查看型号
cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq
#查看物理插槽数量
cat /proc/cpuinfo | grep "physical id" | uniq |wc -l
#查看内核数量
cat /proc/cpuinfo |grep "cpu cores" |uniq |awk '{print $NF}'
#查看逻辑CPU数量
cat /proc/cpuinfo | grep "physical id" |wc -l
```
# 2. 内存

```
#方法1
free -h |grep Mem |awk '{print $2}'
#方法2
cat  /proc/meminfo | grep MemTotal
```
# 3. 硬盘

```
#查看磁盘硬件信息
lsblk
#查看文件系统
df -hT
```
# 4. 网卡

```
#查看所有网卡信息
lspci | grep Ethernet
```

```
#查看所有网卡的名称
for i in `lspci |grep Ethernet |awk '{print $1}' |xargs`
do
	lshw -C network -businfo |grep $i |awk '{print $2}'
done
```

```
#查看活动的网卡
for i in `lspci |grep Ethernet |awk '{print $1}' |xargs`
do
	NIC=`lshw -C network -businfo |grep $i |awk '{print $2}'`
	if ip link show $NIC |grep LOWER_UP;then
		echo $NIC
	fi
done
```
# 5. 显卡

```
#查看硬件信息
lspci | grep VGA

```
# 6. 系统版本

```
#查看内核版本
uname -r
#查看系统版本
cat /etc/os-release
cat /etc/system-release
cat /etc/issue
lsb_release -a
hostnamectl status
```

```
#RedHat_CentOS系列查看详细版本号
lsb_release -a |grep Release |awk '{print $NF}'
cat /etc/redhat-release | awk '{print $(NF-1)}'
lsb_release -a |grep Description |awk '{print $(NF-1)}'
```

```
#KylinV10
cat /etc/.kyinfo
```

```
#Alpine
lsb_release -a |grep Release |awk '{print $NF}'
```

```
#Debian和Ubuntu详细版本号
hostnamectl status
lsb_release -a |grep Description |awk '{print $(NF-1)}'
```
# 7. 硬件厂商信息

```
#厂商
dmidecode -t system |grep Manufacturer |awk '{print $NF}'
#产品型号
dmidecode -t system |grep Version |awk -F : '{print $NF}' |sed "s/^ //g"
#产品序列号
dmidecode -t system |grep "Serial Number" |awk -F : '{print $NF}' |sed "s/^ //g"
```
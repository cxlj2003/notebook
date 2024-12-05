# 1. Cephadm

## 1.1 操作系统

Ubuntu 24.01LTS
## 1.2 先决条件

- Python 3    
- Systemd    
- Podman or Docker for running containers    
- Time synchronization    
- LVM2 for provisioning storage devices
	### 1.2.1 基础网络配置

```
cat << EOF > /etc/modules-load.d/bonding.conf
bonding
EOF
modprobe bonding
lsmod | grep bonding

rm -rf /etc/netplan/*
cat <<EOF > /etc/netplan/bonds.yaml
network:
  ethernets:
    ens32:
      dhcp4: no
    ens34:
      dhcp4: no
    ens35:
      dhcp4: no
    ens36:
      dhcp4: no
    ens37:
      dhcp4: no
    ens38:
      dhcp4: no
    ens39:
      dhcp4: no
    ens40:
      dhcp4: no
  bonds:
    bond1:
      macaddress: 18:80:51:10:01:11
      interfaces:
        - ens32
        - ens34
      parameters:
        mode: active-backup
        primary: ens32
        mii-monitor-interval: 100
      addresses: 
        - "198.51.100.111/24"
      routes:
        - to: default
          via: "198.51.100.254"
      nameservers:
        addresses:
          - "8.8.8.8"
          - "8.8.4.4"
    bond2:
      macaddress: 18:80:19:03:21:11
      interfaces:
        - ens35
        - ens36
      parameters:
        mode: active-backup
        primary: ens35
        mii-monitor-interval: 100
      addresses: 
        - "198.19.32.111/24"
    bond3:
      macaddress: aa:80:51:10:01:11
      interfaces:
        - ens37
        - ens38
      parameters:
        mode: active-backup
        primary: ens37
        mii-monitor-interval: 100
    bond4:
      macaddress: 18:80:19:03:31:11
      interfaces:
        - ens39
        - ens40
      parameters:
        mode: active-backup
        primary: ens39
        mii-monitor-interval: 100
      addresses: 
        - "198.19.33.111/24"
EOF

chmod 600 /etc/netplan/bonds.yaml
netplan apply
```
### 1.2.2 playbook

```
cat << 'EOF' > /opt/playbook
198.51.100.111 node1.ait.lo node1 1qaz#EDC
198.51.100.112 node2.ait.lo node2 1qaz#EDC
198.51.100.113 node3.ait.lo node3 1qaz#EDC
EOF
```
### 1.2.3 配置apt源

```
echo export DEBIAN_FRONTEND=noninteractive > /etc/profile.d/apt.sh
source /etc/profile
mirrors_server='mirrors.ustc.edu.cn'
source /etc/os-release
rm -rf /etc/apt/sources.list.d/*
cat << EOF > /etc/apt/sources.list
deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-security main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-security main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main restricted universe multiverse

# deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
# deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
EOF
apt update &> /dev/null && apt -y upgrade &> /dev/null
apt -y install lrzsz &> /dev/null
```

### 1.2.4 配置域名解析

```
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
# Openstack
EOF
cat /opt/playbook |awk '{print $1" "$2" "$3}' >> /etc/hosts
hostip=`ip add show dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
HostName=`cat /opt/playbook |grep $hostip |awk '{print $3}'`
hostnamectl set-hostname $HostName
```

### 1.2.5 ssh对等

```
apt update &> /dev/null && apt -y install sshpass  &> /dev/null
if [ ! -e /root/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
fi
hosts=`cat /opt/playbook |sort |uniq |awk '{print $1}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/playbook|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done
hosts=`cat /opt/playbook |sort |uniq |awk '{print $2}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/playbook|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done
hosts=`cat /opt/playbook |sort |uniq |awk '{print $3}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/playbook|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done
```

### 1.2.6 Ansible

```
apt update &> /dev/null && apt -y install ansible-core &> /dev/null
if [ ! -e /etc/ansible ];then
	mkdir -p /etc/ansible
fi
cat << EOF > /etc/ansible/hosts
[admin]
node1
[controllers]
node1
node2
node3
[computes]
node1
node2
node3
[storages]
node1
node2
node3
EOF
ansible all -m ping
```

### 1.2.7 基础配置脚本

```
cat << 'EEOOFF' > /opt/baseconfig.sh
#1.playbook
#ansible sync
#2.apt源
echo export DEBIAN_FRONTEND=noninteractive > /etc/profile.d/apt.sh
source /etc/profile
mirrors_server='mirrors.ustc.edu.cn'
source /etc/os-release
rm -rf /etc/apt/sources.list.d/*
cat << EOF > /etc/apt/sources.list
deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-security main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-security main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main restricted universe multiverse

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main restricted universe multiverse
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main restricted universe multiverse

# deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
# deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
EOF
apt update &> /dev/null && apt -y upgrade &> /dev/null
apt -y install lrzsz &> /dev/null
#3.域名解析
cat << 'EOF' > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
# Openstack
EOF
cat /opt/playbook |awk '{print $1" "$2" "$3}' >> /etc/hosts
hostip=`ip add show dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
HostName=`cat /opt/playbook |grep $hostip |awk '{print $3}'`
hostnamectl set-hostname $HostName

#4.Ntp配置
apt update &> /dev/null
apt -y install chrony &> /dev/null
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &> /dev/null
sed -i '/^pool.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^server.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^allow.*/d' /etc/chrony/chrony.conf

cat << EOF > /etc/chrony/chrony.conf
server time.windows.com iburst
server pool.ntp.org iburst
allow 0.0.0.0/0
EOF
systemctl restart chrony &> /dev/null

#5.系统限制
cat << EOF > /etc/security/limits.conf
* soft nofile 65535 #软限制
* hard nofile 65535 #硬限制
EOF
ulimit -a &> /dev/null

#6.安装docker组件
apt install docker.io -y &> /dev/null
#7.关闭swap
swapoff -a
sed -i "s|/swap|#/swap|" /etc/fstab
#8.关闭非必要的系统服务
systemctl disable ufw apparmor --now
EEOOFF

files='
playbook
baseconfig.sh
'
for f in $files;do
ansible 'all:!admin' -m synchronize -a "src=/opt/$f dest=/opt/$f"
done

ansible all -m shell -a "bash /opt/baseconfig.sh"
```


## 1.3 安装cephadm

```
apt install cephadm=19.2.0-0ubuntu0.24.04.1 -y 
```

## 1.4 Ceph容器镜像

[https://quay.io/repository/ceph/ceph](https://quay.io/repository/ceph/ceph) [https://hub.docker.com/r/ceph](https://hub.docker.com/r/ceph)

```
docker pull quay.io/ceph/ceph:v19.2.0
```
# 2. 
# 1.部署环境

| 主机名   | 管理地址           | VTEP          | Provider | FQDN                  | 角色   | 备注  |
| :---- | :------------- | :------------ | :------- | :-------------------- | :--- | :-- |
| node1 | 198.51.100.101 | 198.19.32.101 |          | node1.openstack.local | 控制节点 |     |
| node2 | 198.51.100.102 | 198.19.32.102 |          | node2.openstack.local | 控制节点 |     |
| node3 | 198.51.100.103 | 198.19.32.103 |          | node3.openstack.local | 控制节点 |     |
| node1 | 198.51.100.101 | 198.19.32.101 |          | node1.openstack.local | 计算节点 |     |
| node2 | 198.51.100.102 | 198.19.32.102 |          | node2.openstack.local | 计算节点 |     |
| node3 | 198.51.100.103 | 198.19.32.103 |          | node3.openstack.local | 计算节点 |     |
| node1 | 198.51.100.101 | 198.19.32.101 |          | node1.openstack.local | 存储节点 |     |
| node2 | 198.51.100.102 | 198.19.32.102 |          | node2.openstack.local | 存储节点 |     |
| node3 | 198.51.100.103 | 198.19.32.103 |          | node3.openstack.local | 存储节点 |     |
>[!注]
>1.每个节点配置3块网卡,4块磁盘
>2.网卡1:管理网;网卡2:VTEP网卡;网卡3:Provider.
>3.操作系统安装时使用lvm逻辑卷


# 2.初始化

## 2.1PlayBook
```
cat << 'EOF' > /opt/playbook
198.51.100.101 node1.openstack.local node1 1qaz#EDC
198.51.100.102 node2.openstack.local node2 1qaz#EDC
198.51.100.103 node3.openstack.local node3 1qaz#EDC
EOF
```

## 2.2配置apt 源
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

## 2.3配置网络

```
apt -y purge cloud-init &> /dev/null
apt -y autoremove &> /dev/null
rm -rf /etc/cloud /var/lib/cloud /etc/netplan
apt -y install inetutils-ping ifupdown &> /dev/null
systemctl mask NetworkManager systemd-resolved apparmor ufw &> /dev/null

cat << EOF > /etc/network/interfaces.d/ifcfg-lo
auto lo
iface lo inet loopback
EOF

ints='
ens32
ens34
'
for int in $ints;do
ip=`ip add sh dev $int |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
cat << EOF > /etc/network/interfaces.d/ifcfg-$int
auto $int
iface $int inet static
address $ip/24
EOF
if [[ $int == `ip route|egrep "default" | awk '{print $5}'` ]];then
cat << EOF >> /etc/network/interfaces.d/ifcfg-$int
gateway `ip route|egrep "default" | awk '{print $3}'`
dns-nameservers 8.8.8.8 114.114.114.114
EOF
fi
done

inter=ens35
cat << EOF > /etc/rc.local
#!/bin/bash -e
ip link set $inter promisc on
ip link set $inter up
EOF
chmod +x /etc/rc.local && bash /etc/rc.local

systemctl enable rc-local.service --now
systemctl restart rc-local.service
systemctl enable networking --now
systemctl restart networking
```

## 2.4配置域名解析
```
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
```

## 2.5ssh对等
```
apt -y install sshpass  &> /dev/null
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

## 2.6Ansible
```
apt -y install ansible &> /dev/null
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

## 2.7基础配置脚本
```
cat << 'EEOOFF' > /opt/baseconfig.sh
#1.playbook
cat << 'EOF' > /opt/playbook
198.51.100.101 node1.openstack.local node1 1qaz#EDC
198.51.100.102 node2.openstack.local node2 1qaz#EDC
198.51.100.103 node3.openstack.local node3 1qaz#EDC
EOF
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
apt -y install chrony &> /dev/null
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &> /dev/null
sed -i '/^pool.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^server.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^allow.*/d' /etc/chrony/chrony.conf

cat << EOF >> /etc/chrony/chrony.conf
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
ulimit -a
EEOOFF
ansible 'all:!admin' -m synchronize -a "src=/opt/baseconfig.sh dest=/baseconfig.sh"
ansible all -m shell -a "bash /opt/baseconfig.sh"
```

## 2.8验证配置
```
ansible all -m shell -a "apt update"
ansible all -m shell -a "cat /etc/hosts"
ansible all -m shell -a "date"
ansible all -m shell -a "ls -l /opt"
ansible all -m shell -a "chronyc sources"
```

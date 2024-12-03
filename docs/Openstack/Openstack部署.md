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
>2.
>2.操作系统安装时使用lvm逻辑卷


# 2.初始化

## 2.1 配置apt 源

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
```

## 2.2配置网络

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
address $ip
netmask 255.255.255.0
EOF
if [[ $int == `ip route|egrep "default" | awk '{print $5}'` ]];then
cat << EOF >> /etc/network/interfaces.d/ifcfg-$int
gateway `ip route|egrep "default" | awk '{print $3}'`
EOF
fi
cat << EOF >> /etc/network/interfaces.d/ifcfg-$int
dns-nameservers 8.8.8.8 114.114.114.114
EOF
done

inter=ens35
cat << EOF > /etc/network/interfaces.d/ifcfg-$inter
auto $inter
iface $inter inet static
ip link set  \$IFACE up
ip link set  \$IFACE down
ip link set \$IFACE promisc on
EOF

cat << EOF > /etc/rc.local
#!/bin/bash -e
ip link set ens35 promisc on
ip link set ens35 up
EOF
chmod +x /etc/rc.local
systemctl restart rc-local.service
systemctl enable rc-local.service

systemctl restart networking
systemctl enable networking --now
```
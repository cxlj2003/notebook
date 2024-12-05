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
>2.网卡1:管理网;网卡2:VTEP网卡;网卡3:Provider
>3.操作系统安装时使用lvm逻辑卷
>4.第二块网卡用于Cinder LVM
>5.第三和第四块用于Swift对象存储


# 2.环境初始化

## 2.1配置网络

在所有节点上修改网络配置,节点1配置如下,其他节点修改两个网卡的IP地址即可.

```
#配置临时IP
int=ens32
ipadd=198.51.100.101/24
gw=198.51.100.254
ip add add $ipadd dev $int
ip link set $int up
ip roue add default via $gw
cat << EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF
systemctl mask systemd-resolved.service
int=ens34
ipadd=198.19.32.101/24
ip add add $ipadd dev $int
ip link set $int up
```

在所有节点上更新网络配置

```
#转换配置模式
apt update &> /dev/null
apt -y purge cloud-init &> /dev/null
apt -y autoremove &> /dev/null
rm -rf /etc/cloud /var/lib/cloud /etc/netplan
apt -y install inetutils-ping ifupdown &> /dev/null
systemctl mask NetworkManager apparmor ufw &> /dev/null

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

## 2.2PlayBook

在节点1操作

```
cat << 'EOF' > /opt/playbook
198.51.100.101 node1.openstack.local node1 1qaz#EDC
198.51.100.102 node2.openstack.local node2 1qaz#EDC
198.51.100.103 node3.openstack.local node3 1qaz#EDC
EOF
```

## 2.3配置apt 源

在节点1操作

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

## 2.4配置域名解析

在节点1操作

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

## 2.5ssh对等

在节点1操作

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

## 2.6Ansible

在节点1操作

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

## 2.7基础配置脚本

在节点1操作

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
EEOOFF
ansible 'all:!admin' -m synchronize -a "src=/opt/baseconfig.sh dest=/opt/baseconfig.sh"
ansible all -m shell -a "bash /opt/baseconfig.sh"
```

## 2.8验证配置

在节点1操作

```
ansible all -m shell -a "apt update"
ansible all -m shell -a "cat /etc/hosts"
ansible all -m shell -a "date"
ansible all -m shell -a "ls -l /opt"
ansible all -m shell -a "chronyc sources"
```

# 3.控制节点配置

## 3.1 Prerequisites

### 3.1.1 MariaDB

OpenStack_DBPASS

```
apt update &> /dev/null
apt install mariadb-server python3-pymysql -y &> /dev/null
cat << 'EOF' > /etc/mysql/mariadb.conf.d/99-openstack.cnf
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF
systemctl restart mariadb &> /dev/null
mysql_root_password='OpenStack_DBPASS'
# Make sure that NOBODY can access the server without a password
if mysql -e "UPDATE mysql.user SET Password = PASSWORD('OpenStack_DBPASS') WHERE User = 'root'" &> /dev/null ;then
# Kill the anonymous users
#mysql -uroot -p$mysql_root_password  -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
#mysql -uroot -p$mysql_root_password  -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
#mysql -uroot -p$mysql_root_password -e "DROP DATABASE test"
# Make our changes take effect
mysql -uroot -p$mysql_root_password -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
else
  echo mysql password updated!  
  mysql -uroot -p$mysql_root_password -e "show databases;"
fi
```

### 3.1.2 RabbitMQ

RABBIT_PASS

```
apt update &> /dev/null
apt install rabbitmq-server -y &> /dev/null
rabbitmqctl add_user openstack RABBIT_PASS &> /dev/null
rabbitmqctl set_permissions openstack ".*" ".*" ".*" &> /dev/null
systemctl restart rabbitmq-server &> /dev/null

```

### 3.1.3 Memcached

```
pt update &> /dev/null
apt install memcached python3-memcache -y &> /dev/null
sed -i '/^-l.*/d' /etc/memcached.conf
echo '-l 0.0.0.0' >> /etc/memcached.conf
systemctl restart memcached &> /dev/null
```

### 3.1.4 完成安装

```
systemctl enable  mariadb rabbitmq-server memcached
```
### 3.1.5 验证配置

```
mysql -uroot -p$mysql_root_password -e "show databases;"
cat /etc/mysql/mariadb.conf.d/99-openstack.cnf
cat /etc/memcached.conf
```

## 3.2 Keystone

### 3.2.1 先决条件

创建Keystone所需的数据库

```
mysql_root_password='OpenStack_DBPASS'
mysql -uroot -p$mysql_root_password -e "create database keystone;"
mysql -uroot -p$mysql_root_password -e "grant all privileges on \
keystone.* to keystone@'localhost' identified by 'KEYSTONE_DBPASS';
"
mysql -uroot -p$mysql_root_password -e "grant all privileges on \
keystone.* to keystone@'%' identified by 'KEYSTONE_DBPASS';
"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

### 3.2.2 安装和配置组件

1.备份并修改keystone配置文件;

- memcache服务器配置
- 数据库配置
- keystone配置

```
apt update &> /dev/null
apt -y install keystone &> /dev/null
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.bak
hostip=`ip add show dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
sed -i "s/^#memcache_servers.*/memcache_servers = ${hostip}:11211/g" /etc/keystone/keystone.conf
sed -i "s#^connection.*#connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@$hostip:3306/keystone#g" /etc/keystone/keystone.conf
sed -i '/^provider = fernet/d' /etc/keystone/keystone.conf
sed -i '/^\[token\]/aprovider = fernet' /etc/keystone/keystone.conf

cat /etc/keystone/keystone.conf |grep -e ^memcache_servers -e ^connection -e ^provider
```

2.初始化数据库和Fernet Keys;

```
su -s /bin/bash keystone -c "keystone-manage db_sync" &> /dev/null
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

3.引导 Identity 服务;

```
export controller=node1.openstack.local
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
--bootstrap-admin-url http://$controller:5000/v3/ \
--bootstrap-internal-url http://$controller:5000/v3/ \
--bootstrap-public-url http://$controller:5000/v3/ \
--bootstrap-region-id RegionOne
```

4.备份和配置Apache;

```
cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
sed -i "/ServerName.*/d" /etc/apache2/apache2.conf
sed -i "/# Global configuration/aServerName $controller" /etc/apache2/apache2.conf
cat /etc/apache2/apache2.conf |grep ServerName
```

### 3.2.3 完成安装

```
systemctl restart apache2
systemctl enable apache2

cat << EOF > /opt/openstack-admin.rc
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://$controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF
```

### 3.2.4 验证配置

```
apt install python3-openstackclient -y &> /dev/null
source /opt/openstack-admin.rc
```

```
openstack domain create --description "An Example Domain" example

openstack project create --domain default \
  --description "Service Project" service

openstack project create --domain default \
  --description "Demo Project" myproject

openstack user create --domain default \
  --password MYUSER_PASS myuser

openstack role create myrole

openstack role add --project myproject --user myuser myrole

cat << EOF > /opt/openstack-demo.rc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=MYUSER_PASS
export OS_AUTH_URL=http://$controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
```

```
openstack domain list
openstack project list
openstack user list
openstack role list
openstack service list

```

```
openstack token issue
```

## 3.3 Glance

### 3.3.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "create database glance;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password GLANCE_PASS glance
openstack user list
openstack project create --domain default --description "Service Project" service
openstack project list
openstack role add --project service --user glance admin
openstack role list
openstack service create --name glance \
--description "OpenStack Image" image
openstack service list
export controller=node1.openstack.local
openstack endpoint create --region RegionOne \
image public http://$controller:9292
openstack endpoint create --region RegionOne \
image internal http://$controller:9292
openstack endpoint create --region RegionOne \
image admin http://$controller:9292
openstack endpoint list
openstack role add --user glance --user-domain Default --system all reader
```

### 3.3.2 安装和配置组件

```
apt install glance -y &> /dev/null
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.bak
openstack endpoint list --service glance --region RegionOne
cat << EOF > /etc/glance/glance-api.conf
[DEFAULT]
bind_host = 0.0.0.0
transport_url = rabbit://openstack:RABBIT_PASS@$controller
enabled_backends=fs:file

[barbican]
[barbican_service_user]
[cinder]
[cors]
[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@$controller/glance
#backend = sqlalchemy
[file]
[glance.store.http.store]
[glance.store.rbd.store]
[glance.store.s3.store]
[glance.store.swift.store]
[glance.store.vmware_datastore.store]
[glance_store]
default_backend = fs
[fs]
filesystem_store_datadir = /var/lib/glance/images/
[healthcheck]
[image_format]
disk_formats = ami,ari,aki,vhd,vhdx,vmdk,raw,qcow2,vdi,iso,ploop.root-tar
[key_manager]
[keystone_authtoken]
www_authenticate_uri  = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[paste_deploy]
flavor = keystone
[profiler]
[store_type_location_strategy]
[task]
[taskflow_executor]
[vault]
[wsgi]
EOF
```

```
cat /etc/glance/glance-api.conf
su -s /bin/sh -c "glance-manage db_sync" glance &> /dev/null
```

### 3.3.3 完成安装

```
service glance-api restart
```

```
systemctl enable glance-api
```

### 3.3.4 验证配置

```
source /opt/openstack-admin.rc
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

glance image-create --name "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --visibility=public

glance image-list

```

## 3.4 Placement

### 3.4.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE placement;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
  IDENTIFIED BY 'PLACEMENT_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password PLACEMENT_PASS placement
openstack role add --project service --user placement admin
openstack service create --name placement \
  --description "Placement API" placement
openstack service list
openstack endpoint create --region RegionOne \
  placement public http://$controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://$controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://$controller:8778
openstack endpoint list
```

### 3.4.2 安装和配置组件

```
apt install placement-api -y &> /dev/null
cp /etc/placement/placement.conf /etc/placement/placement.conf.bak
cat << EOF > /etc/placement/placement.conf
[DEFAULT]
[api]
auth_strategy = keystone
[cors]
[keystone_authtoken]
auth_url = http://$controller:5000/v3
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_PASS
[oslo_middleware]
[oslo_policy]
[placement]
[placement_database]
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@$controller/placement
[profiler]
EOF
```

```
cat /etc/placement/placement.conf
su -s /bin/sh -c "placement-manage db sync" placement &> /dev/null
```

### 3.4.3 完成安装

```
systemctl restart apache2
```

```
systemctl enable apache2
```

### 3.4.4 验证配置

```
source /opt/openstack-admin.rc
placement-status upgrade check
```

```
apt install python3-osc-placement -y &> /dev/null
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
```

## 3.5 Nova

### 3.5.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE nova_api;"
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE nova;"
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE nova_cell0;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';
"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY 'NOVA_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY 'NOVA_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
export controller=node1.openstack.local
openstack endpoint create --region RegionOne \
  compute public http://$controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://$controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://$controller:8774/v2.1
```

### 3.5.2 安装和配置组件

```

apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y &> /dev/null
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
```

```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add show dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller:5672/
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova_api
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = \$my_ip
server_proxyclient_address = \$my_ip
[workarounds]
[wsgi]
[zvm]
[cells]
#enable = False
[os_region_name]
openstack = 
EOF
```

```
sed -i '/\[scheduler\]/adiscover_hosts_in_cells_interval = 300' /etc/nova/nova.conf
```

```
cat /etc/nova/nova.conf
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```

### 3.5.3 完成安装

```
service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
```

```
systemctl enable nova-api
systemctl enable nova-scheduler
systemctl enable nova-conductor
systemctl enable nova-novncproxy
```

手动扫描计算主机
```
source /opt/openstack-admin.rc
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
openstack compute service list --service nova-compute
```


### 3.5.4 验证配置

```
openstack compute service list
source /opt/openstack-admin.rc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check
```

## 3.6 Neutron

### 3.6.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE neutron;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
export controller=node1.openstack.local
openstack endpoint create --region RegionOne \
  network public http://$controller:9696
openstack endpoint create --region RegionOne \
  network internal http://$controller:9696
openstack endpoint create --region RegionOne \
  network admin http://$controller:9696
```
### 3.6.2 配置网络选项

```
apt install neutron-server neutron-plugin-ml2 \
  neutron-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent -y &> /dev/null
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
```

```
cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
core_plugin = ml2
service_plugins = router
transport_url = rabbit://openstack:RABBIT_PASS@$controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
agent_down_time = 75
[agent]
root_helper = "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"
report_interval = 30
[cache]
[cors]
[database]
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@$controller/neutron
[healthcheck]
[ironic]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = NEUTRON_PASS
[nova]
auth_url = http://$controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[placement]
[privsep]
[profiler]
[quotas]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[ssl]
EOF
```

```
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.bak
cat << EOF > /etc/neutron/plugins/ml2/ml2_conf.ini
[DEFAULT]
[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security
[ml2_type_flat]
flat_networks = provider
[ml2_type_geneve]
[ml2_type_gre]
[ml2_type_vlan]
[ml2_type_vxlan]
vni_ranges = 1:1000
[ovs_driver]
[securitygroup]
[sriov_driver]
EOF
```

```
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak
PROVIDER_BRIDGE_NAME=ovs-br-provider
PROVIDER_INTERFACE_NAME=ens35
OVERLAY_INTERFACE_IP_ADDRESS=`ip add sh dev ens34 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
##OVERLAY_INTERFACE是指vxlan的endpoint接口,使用第二块网卡.
ovs-vsctl add-br $PROVIDER_BRIDGE_NAME
ovs-vsctl add-port $PROVIDER_BRIDGE_NAME $PROVIDER_INTERFACE_NAME

cat << EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]
[agent]
tunnel_types = vxlan
l2_population = true
[dhcp]
[network_log]
[ovs]
bridge_mappings = provider:$PROVIDER_BRIDGE_NAME
local_ip = $OVERLAY_INTERFACE_IP_ADDRESS
[securitygroup]
enable_security_group = true
firewall_driver = openvswitch
#firewall_driver = iptables_hybrid
EOF

#firewall_driver = iptables_hybrid额外配置如下内容:
#cat << EOF > /etc/sysctl.d/99-ovs-br.conf
#net.bridge.bridge-nf-call-iptables=1
#net.bridge.bridge-nf-call-ip6tables=1
#EOF
#sysctl -p

```

```
cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.bak
cat << EOF > /etc/neutron/l3_agent.ini
[DEFAULT]
interface_driver = openvswitch
[agent]
[network_log]
[ovs]
EOF
```

```
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.bak
cat << EOF > /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = openvswitch
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
[agent]
[ovs]
EOF
```
### 3.6.3 配置元数据代理

```
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.bak
cat << EOF > /etc/neutron/metadata_agent.ini
[DEFAULT]
nova_metadata_host = $controller
metadata_proxy_shared_secret = METADATA_SECRET
[agent]
[cache]
EOF
```

### 3.6.4 计算服务对接网络服务

```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller:5672/
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova_api
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
auth_url = http://$controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = \$my_ip
server_proxyclient_address = \$my_ip
[workarounds]
[wsgi]
[zvm]
[cells]
#enable = False
[os_region_name]
openstack = 
EOF
```

### 3.6.5 完成安装

```
cat /etc/neutron/neutron.conf
cat /etc/neutron/plugins/ml2/ml2_conf.ini
ovs-vsctl show
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini
cat /etc/neutron/l3_agent.ini
cat /etc/neutron/dhcp_agent.ini
cat /etc/neutron/metadata_agent.ini
```

```
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```

```
service nova-api restart
service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
```

```
systemctl enable nova-api
systemctl enable neutron-server
systemctl enable neutron-openvswitch-agent
systemctl enable neutron-dhcp-agent
systemctl enable neutron-metadata-agent
systemctl enable neutron-l3-agent
```

### 3.6.6 验证配置

```
ovs-vsctl show
service nova-api status
service neutron-server status
service neutron-openvswitch-agent status
service neutron-dhcp-agent status
service neutron-metadata-agent status
service neutron-l3-agent status
```

```
openstack network agent list
openstack extension list --network
```
## 3.7 Horizon

### 3.7.1 先决条件

- Keystone服务部署完成
- Python 3.8 or 3.11
- Django 4.2
```
apt install conda-package-handling -y
```
### 3.7.2 安装和配置组件

```
apt install openstack-dashboard -y &> /dev/null
```
	
```
cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.bak
cat << EOF > /etc/openstack-dashboard/local_settings.py
import os
from django.utils.translation import gettext_lazy as _
from horizon.utils import secret_key
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
ALLOWED_HOSTS = ['*']
LOCAL_PATH = os.path.dirname(os.path.abspath(__file__))
SECRET_KEY = secret_key.generate_or_read_from_file('/var/lib/openstack-dashboard/secret_key')
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': 'node1.openstack.local:11211',
    },
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "node1.openstack.local"
#OPENSTACK_KEYSTONE_URL = "http://%s/identity/v3" % OPENSTACK_HOST
#官网错误
OPENSTACK_KEYSTONE_URL = "http://%s:5000" % OPENSTACK_HOST 
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
TIME_ZONE = "UTC"
LOGGING = {
    'version': 1,
    # When set to True this will disable all logging except
    # for loggers specified in this configuration dictionary. Note that
    # if nothing is specified here and disable_existing_loggers is True,
    # django.db.backends will still log unless it is disabled explicitly.
    'disable_existing_loggers': False,
    # If apache2 mod_wsgi is used to deploy OpenStack dashboard
    # timestamp is output by mod_wsgi. If WSGI framework you use does not
    # output timestamp for logging, add %(asctime)s in the following
    # format definitions.
    'formatters': {
        'console': {
            'format': '%(levelname)s %(name)s %(message)s'
        },
        'operation': {
            # The format of "%(message)s" is defined by
            # OPERATION_LOG_OPTIONS['format']
            'format': '%(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'logging.NullHandler',
        },
        'console': {
            # Set the level to "DEBUG" for verbose output logging.
            'level': 'DEBUG' if DEBUG else 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'console',
        },
        'operation': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'operation',
        },
    },
    'loggers': {
        'horizon': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'horizon.operation_log': {
            'handlers': ['operation'],
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_dashboard': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'novaclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'cinderclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneauth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'glanceclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'neutronclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'swiftclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'oslo_policy': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_auth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        # Logging from django.db.backends is VERY verbose, send to null
        # by default.
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'urllib3': {
            'handlers': ['null'],
            'propagate': False,
        },
        'chardet.charsetprober': {
            'handlers': ['null'],
            'propagate': False,
        },
        'iso8601': {
            'handlers': ['null'],
            'propagate': False,
        },
        'scss': {
            'handlers': ['null'],
            'propagate': False,
        },
    },
}
SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': _('All TCP'),
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': _('All UDP'),
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': _('All ICMP'),
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}
DEFAULT_THEME = 'ubuntu'
WEBROOT='/horizon/'
ALLOWED_HOSTS = ['*']
COMPRESS_OFFLINE = True
EOF
```

```
#python版本大于3.11
#Django 大于5.0
sed -i \
's/django.core.cache.backends.memcached.MemcachedCache/django.core.cache.backends.memcached.PyMemcacheCache/g' /etc/openstack-dashboard/local_settings.py
```

```
cp /etc/apache2/conf-available/openstack-dashboard.conf /etc/apache2/conf-available/openstack-dashboard.conf.bak
cat /etc/apache2/conf-available/openstack-dashboard.conf |grep -E 'WSGIApplicationGroup %{GLOBAL}'
```

### 3.7.3 完成安装

```
systemctl reload apache2
systemctl restart apache2
```

### 3.7.4 验证配置

```
#配置host文件
198.51.100.101 node1.openstack.local node1 
198.51.100.102 node2.openstack.local node2 
198.51.100.103 node3.openstack.local node3 
#http://node1.openstack.local/horizon/
##admin ADMIN_PASS
##myuser MYUSER_PASS
```

## 3.8 Swift

### 3.8.1 先决条件

```
source /opt/openstack-admin.rc
openstack user create --domain default --password SWIFT_PASS swift
openstack role add --project service --user swift admin
openstack service create --name swift \
  --description "OpenStack Object Storage" object-store
openstack endpoint create --region RegionOne \
  object-store public http://$controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne \
  object-store internal http://$controller:8080/v1/AUTH_%\(project_id\)s
openstack endpoint create --region RegionOne \
  object-store admin http://$controller:8080/v1
```

### 3.8.2 安装和配置组件

```
apt-get install swift swift-proxy python3-swiftclient \
  python3-keystoneclient python3-keystonemiddleware \
  memcached -y &> /dev/null
if [ ! -e /etc/swift ];then
	mkdir /etc/swift
fi
curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/master/etc/proxy-server.conf-sample
cp /etc/swift/proxy-server.conf /etc/swift/proxy-server.conf.bak
```

```
cat << EOF > /etc/swift/proxy-server.conf
[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift
[pipeline:main]
#pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats \
#container_sync bulk tempurl ratelimit tempauth copy container-quotas account-quotas slo \
#dlo versioned_writes symlink proxy-logging proxy-server
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk \
ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes \
proxy-logging proxy-server
[app:proxy-server]
use = egg:swift#proxy
account_autocreate = True
#[filter:tempauth]
#use = egg:swift#tempauth
#user_admin_admin = admin .admin .reseller_admin
#user_admin_auditor = admin_ro .reseller_reader
#user_test_tester = testing .admin
#user_test_tester2 = testing2 .admin
#user_test_tester3 = testing3
#user_test2_tester2 = testing2 .admin
#user_test5_tester5 = testing5 service
[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin,user
[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = swift
password = SWIFT_PASS
delay_auth_decision = True
[filter:s3api]
use = egg:swift#s3api
[filter:s3token]
use = egg:swift#s3token
#reseller_prefix = AUTH_
#delay_auth_decision = False
#auth_uri = http://keystonehost:5000/v3
#http_timeout = 10.0
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:cache]
use = egg:swift#memcache
memcache_servers = $controller:11211
[filter:ratelimit]
use = egg:swift#ratelimit
[filter:read_only]
use = egg:swift#read_only
[filter:domain_remap]
use = egg:swift#domain_remap
[filter:catch_errors]
use = egg:swift#catch_errors
[filter:cname_lookup]
use = egg:swift#cname_lookup
[filter:staticweb]
use = egg:swift#staticweb
#[filter:tempurl]
#use = egg:swift#tempurl
[filter:formpost]
use = egg:swift#formpost
[filter:name_check]
use = egg:swift#name_check
[filter:etag-quoter]
use = egg:swift#etag_quoter
[filter:list-endpoints]
use = egg:swift#list_endpoints
[filter:proxy-logging]
use = egg:swift#proxy_logging
[filter:bulk]
use = egg:swift#bulk
[filter:slo]
use = egg:swift#slo
[filter:dlo]
use = egg:swift#dlo
[filter:container-quotas]
use = egg:swift#container_quotas
[filter:account-quotas]
use = egg:swift#account_quotas
[filter:gatekeeper]
use = egg:swift#gatekeeper
[filter:container_sync]
use = egg:swift#container_sync
[filter:xprofile]
use = egg:swift#xprofile
[filter:versioned_writes]
use = egg:swift#versioned_writes
[filter:copy]
use = egg:swift#copy
[filter:keymaster]
use = egg:swift#keymaster
meta_version_to_write = 2
encryption_root_secret = changeme
[filter:kms_keymaster]
use = egg:swift#kms_keymaster
[filter:kmip_keymaster]
use = egg:swift#kmip_keymaster
[filter:encryption]
use = egg:swift#encryption
[filter:listing_formats]
use = egg:swift#listing_formats
[filter:symlink]
use = egg:swift#symlink
EOF
```

### 3.8.3 创建并分发初始环

账户环
```
cd /etc/swift
swift-ring-builder account.builder create 10 3 1

STORAGE_NODE_MANAGEMENT_INTERFACE_IP_ADDRESS='
198.51.100.101
198.51.100.102
198.51.100.103
'
DEVICE_NAME='
sdc
sdd
'
DEVICE_WEIGHT=100
for i in $STORAGE_NODE_MANAGEMENT_INTERFACE_IP_ADDRESS;
do 
for j in $DEVICE_NAME;
		do 
swift-ring-builder account.builder \
  add --region 1 --zone 1 --ip $i --port 6202 \
  --device $j --weight $DEVICE_WEIGHT
done
done
```

```
swift-ring-builder account.builder
swift-ring-builder account.builder rebalance
```
容器环
```
cd /etc/swift
swift-ring-builder container.builder create 10 3 1

for i in $STORAGE_NODE_MANAGEMENT_INTERFACE_IP_ADDRESS;
	do for j in $DEVICE_NAME;
		do 
swift-ring-builder container.builder \
  add --region 1 --zone 1 --ip $i --port 6201 \
  --device $j --weight $DEVICE_WEIGHT
  done
done
```

```
swift-ring-builder container.builder
swift-ring-builder container.builder rebalance
```
对象环
```
cd /etc/swift
swift-ring-builder object.builder create 10 3 1

for i in $STORAGE_NODE_MANAGEMENT_INTERFACE_IP_ADDRESS;
	do for j in $DEVICE_NAME;
		do 
swift-ring-builder object.builder \
  add --region 1 --zone 1 --ip $i --port 6200 \
  --device $j --weight $DEVICE_WEIGHT
  done
done
```

```
swift-ring-builder object.builder
swift-ring-builder object.builder rebalance
```
分发环配置文件
```
ansible 'storages!admin' -m shell -a 'mkdir /etc/swift"'
files='
account.ring.gz
container.ring.gz
object.ring.gz
'
for f in $files;
do
  ansible storages -m synchronize -a "src=/etc/swift/$f dest=/etc/swift/$f"
done
ansible storages -m shell -a "ls -l /etc/swift/"
```

### 3.8.4 完成安装

```
curl -o /etc/swift/swift.conf \
  https://opendev.org/openstack/swift/raw/branch/master/etc/swift.conf-sample
cp /etc/swift/swift.conf /etc/swift/swift.conf.bak
```

```
HASH_PATH_SUFFIX=HASH_PATH_SUFFIX_
HASH_PATH_PREFIX=HASH_PATH_PREFIX_
cat << EOF > /etc/swift/swift.conf
[swift-hash]
swift_hash_path_suffix = $HASH_PATH_SUFFIX
swift_hash_path_prefix = $HASH_PATH_PREFIX
[storage-policy:0]
name = Policy-0
default = yes
aliases = yellow, orange
[swift-constraints]
EOF
```

```
cat /etc/swift/swift.conf
files='
swift.conf
'
for f in $files;
do
  ansible storages -m synchronize -a "src=/etc/swift/$f dest=/etc/swift/$f"
done

chown -R root:swift /etc/swift
service memcached restart
service swift-proxy restart
```

完成[[Openstack部署#5.1 Swift]]的配置后执行
### 3.8.5 验证配置

```
ansible storages -m shell -a "chown -R root:swift /etc/swift"
ansible storages -m shell -a "swift-init all start"
ansible storages -m shell -a "swift-init all restart"
```

```

ansible storages -m shell -a "chcon -R system_u:object_r:swift_data_t:s0 /srv/node"
source /opt/openstack-admin.rc
swift stat
openstack container create container1
openstack container list
```

```
cd 
echo 'This is a testing file!' > testfile
openstack object create container1 testfile
openstack object list container1
rm -rf testfile
openstack object save container1 testfile
cat testfile
rm -rf testfile
```

## 3.9 Cinder

### 3.9.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE cinder;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
  IDENTIFIED BY 'CINDER_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
  IDENTIFIED BY 'CINDER_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password CINDER_PASS cinder
openstack role add --project service --user cinder admin
openstack service create --name cinderv3 \
  --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne \
  volumev3 public http://$controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev3 internal http://$controller:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne \
  volumev3 admin http://$controller:8776/v3/%\(project_id\)s
```
### 3.9.2 安装和配置组件

```
apt install cinder-api cinder-scheduler -y &> /dev/null
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.bak
```

```
cat << EOF > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller
auth_strategy = keystone
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = lioadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
enabled_backends = lvm
[database]
connection = mysql+pymysql://cinder:CINDER_DBPASS@$controller/cinder
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_PASS
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
EOF
```

```
su -s /bin/sh -c "cinder-manage db sync" cinder
```

### 3.9.3 计算服务对接存储服务

```
sed -i '/\[cinder\]/aos_region_name = RegionOne' /etc/nova/nova.conf
```

### 3.9.4 完成安装

```
service nova-api restart
service cinder-scheduler restart
service apache2 restart
```

```
systemctl enable cinder-scheduler
```

完成[[Openstack部署#5.2 块存储]]
## 3.10 Heat

编排服务
### 3.10.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE heat;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' \
  IDENTIFIED BY 'HEAT_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' \
  IDENTIFIED BY 'HEAT_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password HEAT_PASS heat
openstack role add --project service --user heat admin
openstack service create --name heat \
  --description "Orchestration" orchestration
openstack service create --name heat-cfn \
  --description "Orchestration"  cloudformation
openstack endpoint create --region RegionOne \
  orchestration public http://$controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  orchestration internal http://$controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  orchestration admin http://$controller:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  cloudformation public http://$controller:8000/v1
openstack endpoint create --region RegionOne \
  cloudformation internal http://$controller:8000/v1
openstack endpoint create --region RegionOne \
  cloudformation admin http://$controller:8000/v1
openstack domain create --description "Stack projects and users" heat
openstack user create --domain heat --password HEAT_DOMAIN_ADMIN_PASS heat_domain_admin
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role add --project demo --user demo heat_stack_owner
openstack role create heat_stack_user
```

### 3.10.2 安装和配置组件

```
apt-get install heat-api heat-api-cfn heat-engine -y
cp /etc/heat/heat.conf /etc/heat/heat.conf.bak
```

```
cat << EOF > /etc/heat/heat.conf

EOF
```

### 3.10.3 完成安装

```
service heat-api restart
service heat-api-cfn restart
service heat-engine restart
```

```
ssystemctl enable heat-api
ssystemctl enable heat-api-cfn
ssystemctl enable heat-engine
```

### 3.10.4 验证配置

```
source /opt/openstack-admin.rc
openstack orchestration service list
```

## 3.11 ceilometer

### 3.11.1 先决条件

```
mysql -uroot -p$mysql_root_password -e "CREATE DATABASE gnocchi;"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON gnocchi.* TO 'gnocchi'@'localhost' \
  IDENTIFIED BY 'GNOCCHI_DBPASS';"
mysql -uroot -p$mysql_root_password -e "GRANT ALL PRIVILEGES ON gnocchi.* TO 'gnocchi'@'%' \
  IDENTIFIED BY 'GNOCCHI_DBPASS';"
mysql -uroot -p$mysql_root_password -e "show databases;"
```

```
source /opt/openstack-admin.rc
openstack user create --domain default --password CEILMETER_PASS ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer \
  --description "Telemetry" metering
openstack user create --domain default --password GNOCCHI_PASS gnocchi
openstack service create --name gnocchi \
  --description "Metric Service" metric
openstack role add --project service --user gnocchi admin
openstack endpoint create --region RegionOne \
  metric public http://$controller:8041
openstack endpoint create --region RegionOne \
  metric internal http://$controller:8041
openstack endpoint create --region RegionOne \
  metric admin http://$controller:8041
```


安装和配置Gnocchi
```
apt-get install gnocchi-api gnocchi-metricd python-gnocchiclient -y
apt-get install uwsgi-plugin-python3 uwsgi -y
cp /etc/gnocchi/gnocchi.conf /etc/gnocchi/gnocchi.conf.bak
```

```
cat << EOF > /etc/gnocchi/gnocchi.conf

EOF
```

```
gnocchi-upgrade
service gnocchi-api restart
service gnocchi-metricd restart
systemctl enable gnocchi-api gnocchi-metricd
```
### 3.11.2 安装和配置组件

```
apt-get install ceilometer-agent-notification \
  ceilometer-agent-central -y
cp /etc/ceilometer/pipeline.yaml /etc/ceilometer/pipeline.yaml.bak
```

```
ceilometer-upgrade
```

### 3.11.3 完成安装

```
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
```

```
systemctl enable ceilometer-agent-central \
ceilometer-agent-notification
```

### 3.11.4 验证配置

```

gnocchi resource list  --type image
IMAGE_ID=$(glance image-list | grep 'cirros' | awk '{ print $2 }')
glance image-download $IMAGE_ID > /tmp/cirros.img

gnocchi measures show 839afa02-1668-4922-a33e-6b6ea7780715
rm /tmp/cirros.img
```

## 3.12 trove(DataBase)

## 3.13 Octavia(LB)
## 3.14 zun(containers)
## 3.15 designate(DNS)

# 4.计算节点

## 4.1 Nova
### 4.1.1 安装和配置组件

```
apt install nova-compute -y &> /dev/null
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
```

单纯计算节点
```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
#connection = sqlite:////var/lib/nova/nova_api.sqlite
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
#connection = sqlite:////var/lib/nova/nova.sqlite
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = \$my_ip
novncproxy_base_url = http://$controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[zvm]
[cells]
enable = False
[os_region_name]
openstack = 
EOF
```

控制和计算节点部署在一起
```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova_api
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = \$my_ip
novncproxy_base_url = http://$controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[zvm]
[cells]
#enable = False
[os_region_name]
openstack = 
EOF
```
### 4.1.2 完成安装

```
cat /etc/nova/nova.conf

if [[ `egrep -c '(vmx|svm)' /proc/cpuinfo` -eq 0 ]];then
 sed -i 's/virt_type=.*/virt_type=qemu/g' /etc/nova/nova-compute.conf
fi
cat /etc/nova/nova.conf |grep virt_type
service nova-compute restart
```

### 4.1.3 验证配置

在控制节点上
```
source /opt/openstack-admin.rc

su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
openstack compute service list --service nova-compute
```

## 4.2 Netron
### 4.2.1 安装和配置组件

```
apt install neutron-openvswitch-agent -y &> /dev/null
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.bak
```

纯计算节点配置如下,控制节点和计算节点在一起,无需修改配置
```
cat << EOF > /etc/neutron/neutron.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@$controller
auth_strategy = keystone
[agent]
root_helper = "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"
report_interval = 30
[cache]
[cors]
[database]
[healthcheck]
[ironic]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = neutron
password = NEUTRON_PASS
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[placement]
[privsep]
[profiler]
[quotas]
[ssl]
EOF
```
### 4.2.2 配置网络选项

纯计算节点配置如下,控制节点和计算节点在一起,无需修改配置
```
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.bak
PROVIDER_BRIDGE_NAME=ovs-br-provider
PROVIDER_INTERFACE_NAME=ens35
OVERLAY_INTERFACE_IP_ADDRESS=`ip add sh dev ens34 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
##OVERLAY_INTERFACE是指vxlan的endpoint接口,使用第二块网卡.
ovs-vsctl add-br $PROVIDER_BRIDGE_NAME
ovs-vsctl add-port $PROVIDER_BRIDGE_NAME $PROVIDER_INTERFACE_NAME
cat << EOF > /etc/neutron/plugins/ml2/openvswitch_agent.ini
[DEFAULT]
[agent]
tunnel_types = vxlan
l2_population = true
[dhcp]
[network_log]
[ovs]
bridge_mappings = provider:$PROVIDER_BRIDGE_NAME
local_ip = $OVERLAY_INTERFACE_IP_ADDRESS
[securitygroup]
enable_security_group = true
firewall_driver = openvswitch
#firewall_driver = iptables_hybrid
EOF

#firewall_driver = iptables_hybrid额外配置如下内容:
#cat << EOF > /etc/sysctl.d/99-ovs-br.conf
#net.bridge.bridge-nf-call-iptables=1
#net.bridge.bridge-nf-call-ip6tables=1
#EOF
#sysctl -p
```

### 4.2.3 计算服务对接网络服务

纯计算节点配置如下:
```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller:5672/
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
#connection = sqlite:////var/lib/nova/nova_api.sqlite
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
#connection = sqlite:////var/lib/nova/nova.sqlite
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
auth_url = http://$controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = \$my_ip
novncproxy_base_url = http://$controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[zvm]
[cells]
enable = False
[os_region_name]
openstack = 
EOF
```

计算节点和控制节点在一起
```
cat << EOF > /etc/nova/nova.conf
[DEFAULT]
my_ip = `ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
transport_url = rabbit://openstack:RABBIT_PASS@$controller:5672/
log_dir = /var/log/nova
lock_path = /var/lock/nova
state_path = /var/lib/nova
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova_api
[barbican]
[barbican_service_user]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
connection = mysql+pymysql://nova:NOVA_DBPASS@$controller/nova
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://$controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000/
auth_url = http://$controller:5000/
memcached_servers = $controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
[libvirt]
[metrics]
[mks]
[neutron]
auth_url = http://$controller:5000
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://$controller:5000/v3
username = placement
password = PLACEMENT_PASS
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
#[service_user]
#send_service_user_token = true
#auth_url = http://$controller:5000/identity
#auth_strategy = keystone
#auth_type = password
#project_domain_name = Default
#project_name = service
#user_domain_name = Default
#username = nova
#password = NOVA_PASS
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = \$my_ip
novncproxy_base_url = http://$controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[zvm]
[cells]
enable = False
[os_region_name]
openstack = 
EOF
```

### 4.2.4 完成安装

```
cat /etc/neutron/neutron.conf
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini
cat /etc/nova/nova.conf
ovs-vsctl show
```

```
service nova-compute restart
service neutron-openvswitch-agent restart
```

### 4.2.5 验证配置

```
source /opt/openstack-admin.rc
openstack network agent list
```
# 5. 存储节点

## 5.1 Swift
### 5.1.1 先决条件

```
apt-get install xfsprogs rsync -y
mkfs.xfs /dev/sdc
mkfs.xfs /dev/sdd
mkdir -p /srv/node/sdc
mkdir -p /srv/node/sdd
cat << EOF >> /etc/fstab
UUID="`blkid /dev/sdc |awk -F \" '{print $2}'`" /srv/node/sdc xfs noatime 0 2
UUID="`blkid /dev/sdd |awk -F \" '{print $2}'`" /srv/node/sdd xfs noatime 0 2
EOF
systemctl daemon-reload
mount /srv/node/sdc
mount /srv/node/sdd
#cp /etc/rsyncd.conf /etc/rsyncd.conf.bak
```

```
MANAGEMENT_INTERFACE_IP_ADDRESS=`ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`

cat << EOF > /etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $MANAGEMENT_INTERFACE_IP_ADDRESS

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock
EOF
```

```
service rsync start
systemctl enable rsync
```

```
df -hT |grep /srv/node/
```
### 5.1.2 安装和配置组件

```
apt-get install swift swift-account swift-container swift-object -y &> /dev/null
if [ ! -e /etc/swift ];then
	mkdir /etc/swift
fi
curl -o /etc/swift/account-server.conf.org https://opendev.org/openstack/swift/raw/branch/master/etc/account-server.conf-sample
curl -o /etc/swift/container-server.conf.org https://opendev.org/openstack/swift/raw/branch/master/etc/container-server.conf-sample
curl -o /etc/swift/object-server.conf.org https://opendev.org/openstack/swift/raw/branch/master/etc/object-server.conf-sample
curl -o /etc/swift/internal-client.conf.org https://opendev.org/openstack/swift/raw/branch/master/etc/internal-client.conf-sample
curl -o /etc/swift/container-reconciler.conf https://opendev.org/openstack/swift/raw/branch/master/etc/container-reconciler.conf-sample
```

```
MANAGEMENT_INTERFACE_IP_ADDRESS=`ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
cat << EOF > /etc/swift/account-server.conf
[DEFAULT]
bind_ip = $MANAGEMENT_INTERFACE_IP_ADDRESS
bind_port = 6202
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True
[pipeline:main]
#pipeline = healthcheck recon backend_ratelimit account-server
pipeline = healthcheck recon account-server
[app:account-server]
use = egg:swift#account
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
[filter:backend_ratelimit]
use = egg:swift#backend_ratelimit
[account-replicator]
[account-auditor]
[account-reaper]
[filter:xprofile]
use = egg:swift#xprofile
EOF
```

```
cat << EOF > /etc/swift/container-server.conf
[DEFAULT]
bind_ip = $MANAGEMENT_INTERFACE_IP_ADDRESS
bind_port = 6201
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True
[pipeline:main]
#pipeline = healthcheck recon backend_ratelimit container-server
pipeline = healthcheck recon container-server
[app:container-server]
use = egg:swift#container
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
[filter:backend_ratelimit]
use = egg:swift#backend_ratelimit
[container-replicator]
[container-updater]
[container-auditor]
[container-sync]
[filter:xprofile]
use = egg:swift#xprofile
[container-sharder]
EOF
```

```
cat << EOF > /etc/swift/object-server.conf
[DEFAULT]
bind_ip = $MANAGEMENT_INTERFACE_IP_ADDRESS
bind_port = 6200
user = swift
swift_dir = /etc/swift
devices = /srv/node
mount_check = True
[pipeline:main]
#pipeline = healthcheck recon backend_ratelimit object-server
pipeline = healthcheck recon object-server
[app:object-server]
use = egg:swift#object
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
recon_lock_path = /var/lock
[filter:backend_ratelimit]
use = egg:swift#backend_ratelimit
[object-replicator]
[object-reconstructor]
[object-updater]
[object-auditor]
[object-expirer]
[filter:xprofile]
use = egg:swift#xprofile
[object-relinker]
EOF
```

```
##internal-client
##官方文档没有此配置
##无此配置swift-init all start报错
cat << EOF > /etc/swift/internal-client.conf
[DEFAULT]
[pipeline:main]
pipeline = catch_errors proxy-logging cache symlink proxy-server
[app:proxy-server]
use = egg:swift#proxy
account_autocreate = true
[filter:symlink]
use = egg:swift#symlink
[filter:cache]
use = egg:swift#memcache
memcache_servers = $controller:11211
[filter:proxy-logging]
use = egg:swift#proxy_logging
[filter:catch_errors]
use = egg:swift#catch_errors
EOF
```
	
```
##官方文档没有此配置
##无此配置swift-init all start报错
cat << EOF > /etc/swift/container-reconciler.conf
[DEFAULT]
[container-reconciler]
[pipeline:main]
pipeline = catch_errors proxy-logging cache proxy-server
[app:proxy-server]
use = egg:swift#proxy
account_autocreate = true
[filter:cache]
use = egg:swift#memcache
memcache_servers = $controller:11211
[filter:proxy-logging]
use = egg:swift#proxy_logging
[filter:catch_errors]
use = egg:swift#catch_errors
EOF
```

### 5.1.3 完成安装

```
chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R swift:swift /srv/node
chown -R root:swift /var/cache/swift
chmod -R 775 /var/cache/swift
```

### 5.1.4 验证配置

返回控制节点验证配置[[Openstack部署#3.8.5 验证配置]]]

## 5.2 Cinder

### 5.2.1 先决条件

```
apt install lvm2 thin-provisioning-tools -y &> /dev/null
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.bak
```

```
##在devices部分，添加一个过滤器，只接受/dev/sdb设备，拒绝其他所有设备：
##存储节点在操作系统磁盘上使用了 LVM，您还必需添加相关的设备到过滤器中。例如，如果 /dev/sda 设备包含操作系统：
##filter = [ "a/sda/", "a/sdb/", "r/.*/" ]
##计算节点在操作系统磁盘上使用了 LVM，您也必需修改这些节点上 /etc/lvm/lvm.conf 文件中的过滤器，将操作系统磁盘包含到过滤器中。
##例如，如果/dev/sda设备包含操作系统：
##filter = [ "a/sda/", "r/.*/" ]
```

```

sed -i '/devices {/afilter = \[ "a/sda/", "a/sdb/", "r/.*/" \]' /etc/lvm/lvm.conf
cat /etc/lvm/lvm.conf |grep 'filter ='
```

### 5.2.2 安装和配置组件

```
apt install cinder-volume tgt -y &> /dev/null
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.bak
```

```

MANAGEMENT_INTERFACE_IP_ADDRESS=`ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
cat << EOF > /etc/cinder/cinder.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@$controller
auth_strategy = keystone
my_ip = $MANAGEMENT_INTERFACE_IP_ADDRESS
glance_api_servers = http://$controller:9292
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = lioadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
enabled_backends = lvm
[database]
#connection = sqlite:////var/lib/cinder/cinder.sqlite
connection = mysql+pymysql://cinder:CINDER_DBPASS@$controller/cinder
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_PASS
[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
EOF
```

```
echo 'include /var/lib/cinder/volumes/*' > /etc/tgt/conf.d/cinder.conf
```

### 5.2.3 完成安装

```
service tgt restart
service cinder-volume restart
```

```
systemctl enable tgt cinder-volume
```
### 5.2.4  验证配置

```
source /opt/openstack-admin.rc
openstack volume service list
```
### 5.2.5 Cinder Backup

```
apt install cinder-backup -y &> /dev/null
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.bak
```

```
openstack catalog show swift |grep public |awk '{print $(NF-1)}'
```

```
MANAGEMENT_INTERFACE_IP_ADDRESS=`ip add sh dev ens32 |grep -Ev 'inet6' |grep inet |awk '{print $2}' |awk -F / '{print $1}'`
SWIFT_URL=http://node1.openstack.local:8080/v1/AUTH_85666f61fcde47cbbd2c3758386c4374
cat << EOF > /etc/cinder/cinder.conf
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@$controller
auth_strategy = keystone
my_ip = $MANAGEMENT_INTERFACE_IP_ADDRESS
glance_api_servers = http://$controller:9292
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = lioadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes
enabled_backends = lvm
backup_driver = cinder.backup.drivers.swift.SwiftBackupDriver
backup_swift_url = $SWIFT_URL
[database]
#connection = sqlite:////var/lib/cinder/cinder.sqlite
connection = mysql+pymysql://cinder:CINDER_DBPASS@$controller/cinder
[keystone_authtoken]
www_authenticate_uri = http://$controller:5000
auth_url = http://$controller:5000
memcached_servers = $controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_PASS
[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
target_protocol = iscsi
target_helper = tgtadm
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
EOF
```

```
service cinder-backup restart
systemctl enable cinder-backup
```

```
source /opt/openstack-admin.rc
openstack volume service list
```

# 6. 启动实例
## 6.1 先决条件
### 6.1.1 创建Provider网络

```
source /opt/openstack-admin.rc
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider
START_IP_ADDRESS=198.51.100.1
END_IP_ADDRESS=198.51.100.100
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_GATEWAY=198.51.100.254
PROVIDER_NETWORK_CIDR=198.51.100.0/24
openstack subnet create --network provider \
  --allocation-pool start=$START_IP_ADDRESS,end=$END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDR provider
```

### 6.1.2 创建VXLAN

```
openstack network create selfservice
DNS_RESOLVER=8.8.8.8
SELFSERVICE_NETWORK_GATEWAY=172.16.0.254
SELFSERVICE_NETWORK_CIDR=172.16.0.0/24
openstack subnet create --network selfservice \
  --dns-nameserver $DNS_RESOLVER --gateway $SELFSERVICE_NETWORK_GATEWAY \
  --subnet-range $SELFSERVICE_NETWORK_CIDR selfservice
```
### 6.1.3 创建路由器并添加网络接口

```
openstack router create router
openstack router add subnet router selfservice
openstack router set router --external-gateway provider
```
### 6.1.4 验证网络

```
ip netns
openstack port list --router router
```

### 6.1.5 创建VM规格

创建1核1G20G
```
openstack flavor create --id 0 --vcpus 1 --ram 1024 --disk 20 m1.nano
```

### 6.1.6 创建密钥

```
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
```

### 6.1.7 新增默认安全组策略

```
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
```

## 6.2 创建VM实例
### 6.2.1 验证先决条件

```
openstack flavor list
openstack image list
openstack network list
openstack security group list
```
### 6.2.2 创建VM实例

```

PROVIDER_NET_ID=`openstack network list | awk '/ provider / { print $2 }'`
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$PROVIDER_NET_ID --security-group default \
  --key-name mykey provider-instance
```

```

SELFSERVICE_NET_ID=`openstack network list | awk '/ selfservice / { print $2 }'`
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$SELFSERVICE_NET_ID --security-group default \
  --key-name mykey selfservice-instance
```

### 6.2.3 查看VM实例状态

```
openstack server list
```

### 6.2.4 控制台连接实例

```
openstack console url show provider-instance
openstack console url show selfservice-instance
```

通过浏览器连接实例
### 6.2.5 远程连接实例

Provier实例通过providerIP连接
```
providerip=`openstack server list |awk '/ provider-instance / {print $8}' |awk -F = '{print $NF}'`
ssh cirros@$providerip
```

VXLAN实例通过FloatingIP连接
```
openstack floating ip create provider
floatingip=
openstack server add floating ip selfservice-instance $floatingip
```

## 6.3 块存储

### 6.3.1 创建卷

```
openstack volume create --size 1 volume1
openstack volume list
```

### 6.3.2 将卷附加到实例

```
INSTANCE_NAME=selfservice-instance
VOLUME_NAME=volume1
openstack server add volume $INSTANCE_NAME $VOLUME_NAME
openstack volume list
```

### 6.3.3 验证

```
lsblk
```
# 7. 使用kolla-ansible部署



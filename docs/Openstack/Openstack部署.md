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

# 3.Controller节点配置

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

### 3.1.4 验证配置

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
export OS_PASSWORD=DEMO_PASS
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
apt install placement-api -y
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
su -s /bin/sh -c "placement-manage db sync" placement
```

### 3.4.3 完成安装

```
systemctl restart apache2
```

### 3.4.4 验证配置

```
source /opt/openstack-admin.rc
placement-status upgrade check
```

```
apt install python3-osc-placement -y
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
apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y
cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
export controller=node1.openstack.local
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
[service_user]
send_service_user_token = true
auth_url = http://$controller:5000/identity
auth_strategy = keystone
auth_type = password
project_domain_name = Default
project_name = service
user_domain_name = Default
username = nova
password = NOVA_PASS
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

```
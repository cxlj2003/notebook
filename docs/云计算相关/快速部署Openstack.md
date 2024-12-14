# 1.部署环境

| 主机名         | bond1          | bond2          | bond3 | bond4          | 角色   |
| ----------- | -------------- | -------------- | ----- | -------------- | ---- |
| controller1 | 172.16.250.101 | 172.16.251.101 |       | 172.16.254.101 | 控制节点 |
| controller2 | 172.16.250.102 | 172.16.251.102 |       | 172.16.254.102 | 控制节点 |
| controller3 | 172.16.250.103 | 172.16.251.103 |       | 172.16.254.103 | 控制节点 |
| compute1    | 172.16.250.104 | 172.16.251.104 |       | 172.16.254.104 | 计算节点 |
| compute2    | 172.16.250.105 | 172.16.251.105 |       | 172.16.254.105 | 计算节点 |
| compute3    | 172.16.250.106 | 172.16.251.106 |       | 172.16.254.106 | 计算节点 |
| storage1    | 172.16.250.107 |                |       | 172.16.254.107 | 存储节点 |
| storage2    | 172.16.250.108 |                |       | 172.16.254.108 | 存储节点 |
| storage3    | 172.16.250.109 |                |       | 172.16.254.109 | 存储节点 |

>[!NOTE]
>
1.网卡8块组成4个bond:  
bond1: 管理  
bond2: 控制  
bond3: 业务 (openstack)  
bond4: 存储  
2.硬盘4块:  
sda:操作系统  
sdb: OSD  
sdc: OSD  
sdd: OSD  
3.操作系统:Ubuntu 24.01LTS
>4.域名:test.local
>参考文档: https://docs.openstack.org/kolla-ansible/2024.2/user/quickstart.html

## 1.1 bond配置
控制节点和计算节点的bond配置
```
cat << EOF > /etc/modules-load.d/bonding.conf
bonding
EOF
modprobe bonding
lsmod | grep bonding

rm -rf /etc/netplan/*
ip4=`ip route |grep -Ev 'default' |awk '{print $NF}' |awk -F . '{print $NF}'`
bond1_active=ens160
bond1_backup=ens192
bond1_addr="172.16.250.${ip4}/24"
bond1_gw='172.16.250.254'
bond2_active=ens224
bond2_backup=ens256
bond2_addr="172.16.251.${ip4}/24"
bond3_active=ens161
bond3_backup=ens193
bond4_active=ens225
bond4_backup=ens257
bond4_addr="172.16.254.${ip4}/24"

cat <<EOF > /etc/netplan/bonds.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${bond1_active}:
      dhcp4: false
    ${bond1_backup}:
      dhcp4: false
    ${bond2_active}:
      dhcp4: false
    ${bond2_backup}:
      dhcp4: false
    ${bond3_active}:
      dhcp4: false
    ${bond3_backup}:
      dhcp4: false
    ${bond4_active}:
      dhcp4: false
    ${bond4_backup}:
      dhcp4: false
  bonds:
    bond1:
      addresses:
      - "${bond1_addr}"
      nameservers:
        addresses:
        - 8.8.8.8
        - 114.114.114.114
        search:
        - local
      interfaces:
      - ${bond1_active}
      - ${bond1_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond1_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
      routes:
      - to: "default"
        via: "${bond1_gw}"
    bond2:
      addresses:
      - "${bond2_addr}"
      interfaces:
      - ${bond2_active}
      - ${bond2_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond2_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
    bond3:
      interfaces:
      - ${bond3_active}
      - ${bond3_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond3_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
    bond4:
      addresses:
      - "${bond4_addr}"
      interfaces:
      - ${bond4_active}
      - ${bond4_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond4_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
EOF

chmod 600 /etc/netplan/bonds.yaml
netplan apply
```

存储节点的bond配置
```
cat << EOF > /etc/modules-load.d/bonding.conf
bonding
EOF
modprobe bonding
lsmod | grep bonding

rm -rf /etc/netplan/*
ip4=`ip route |grep -Ev 'default' |awk '{print $NF}' |awk -F . '{print $NF}'`
bond1_active=ens160
bond1_backup=ens192
bond1_addr="172.16.250.${ip4}/24"
bond1_gw='172.16.250.254'
bond2_active=ens224
bond2_backup=ens256
bond2_addr="172.16.254.${ip4}/24"
cat <<EOF > /etc/netplan/bonds.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${bond1_active}:
      dhcp4: false
    ${bond1_backup}:
      dhcp4: false
    ${bond2_active}:
      dhcp4: false
    ${bond2_backup}:
      dhcp4: false
  bonds:
    bond1:
      addresses:
      - "${bond1_addr}"
      nameservers:
        addresses:
        - 8.8.8.8
        - 114.114.114.114
        search:
        - local
      interfaces:
      - ${bond1_active}
      - ${bond1_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond1_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
      routes:
      - to: "default"
        via: "${bond1_gw}"
    bond2:
      addresses:
      - "${bond2_addr}"
      interfaces:
      - ${bond2_active}
      - ${bond2_backup}
      parameters:
        mode: "active-backup"
        primary: "${bond2_active}"
        mii-monitor-interval: "1"
        fail-over-mac-policy: "active"
        gratuitous-arp: 5
EOF

chmod 600 /etc/netplan/bonds.yaml
netplan apply
```
## 1.2 域名解析

```
cat << 'EOF' > /opt/plan
172.16.250.101 controller1.test.local controller1 1qaz#EDC
172.16.250.102 controller2.test.local controller2 1qaz#EDC
172.16.250.103 controller3.test.local controller3 1qaz#EDC
172.16.250.104 compute1.test.local compute1 1qaz#EDC
172.16.250.105 compute2.test.local compute2 1qaz#EDC
172.16.250.106 compute3.test.local compute3 1qaz#EDC
172.16.250.107 storage1.test.local storage1 1qaz#EDC
172.16.250.108 storage2.test.local storage2 1qaz#EDC
172.16.250.109 storage3.test.local storage3 1qaz#EDC
EOF
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF
cat /opt/plan |awk '{print $1" "$2" "$3}' >> /etc/hosts
```
## 1.3 apt源
```
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

echo export DEBIAN_FRONTEND=noninteractive > /etc/profile.d/apt.sh && source /etc/profile &> /dev/null
apt update &> /dev/null  && apt -y upgrade &> /dev/null
```

## 1.4 ssh免密

```
apt update &> /dev/null
apt -y install sshpass &> /dev/null

if [ ! -e /root/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N '' &> /dev/null
fi

hosts=`cat /opt/plan |sort |uniq |awk '{print $1}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

hosts=`cat /opt/plan |sort |uniq |awk '{print $2}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

hosts=`cat /opt/plan |sort |uniq |awk '{print $3}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

```

## 1.5 Ansible

```
apt -y install ansible &> /dev/null
cat << EOF > /opt/ansibe-hosts
[admin]
`cat /opt/plan |sort |uniq |grep controller1 |awk '{print $1}'`
[controllers]
`cat /opt/plan|sort |uniq |grep controller |awk '{print $1}'`
[computes]
`cat /opt/plan |sort |uniq |grep compute |awk '{print $1}'`
[storages]
`cat /opt/plan |sort |uniq |grep storage |awk '{print $1}'`
EOF
if [ ! -e /etc/ansible ];then
	mkdir -p /etc/ansible
fi
cat /opt/ansibe-hosts > /etc/ansible/hosts
ansible all -m ping
```

## 1.6 基础配置脚本

```
cat << 'EEOOFF' > /opt/baseconfig.sh
#!/bin/bash
set -ex
#主机名
mgmtnic=`ip route |grep default |awk '{print $(NF-2)}'`
hostip=`ip route |grep -Ev "br|docker|default" |grep $mgmtnic |awk '{print $NF}'`
HostName=`cat /opt/plan |grep $hostip |awk '{print $3}'`
hostnamectl set-hostname $HostName
#域名解析
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF
cat /opt/plan |awk '{print $1" "$2" "$3}' >> /etc/hosts
#apt源
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

echo export DEBIAN_FRONTEND=noninteractive > /etc/profile.d/apt.sh && source /etc/profile &> /dev/null
apt update &> /dev/null  && apt -y upgrade &> /dev/null
#基础环境
apt install git python3-dev libffi-dev gcc libssl-dev -y &> /dev/null
#NTP
apt -y install chrony &> /dev/null
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sed -i '/^pool.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^server.*iburst/d' /etc/chrony/chrony.conf
sed -i '/^allow/d' /etc/chrony/chrony.conf
if [[ $HostName == 'controller1' || $HostName == 'controller2' || $HostName == 'controller3' ]];then
#ntpserver
cat << EOF >> /etc/chrony/chrony.conf
server time.windows.com iburst
server pool.ntp.org iburst
allow 0.0.0.0/0
EOF
systemctl restart chrony
else
#ntpclient
cat << EOF >> /etc/chrony/chrony.conf
server controller1 iburst
server controller2 iburst
server controller3 iburst
EOF
systemctl restart chrony
fi
#安全相关
systemctl disable  ufw --now && systemctl mask ufw &> /dev/null
systemctl disable apparmor --now && systemctl mask apparmor &> /dev/null
set +ex
EEOOFF

#将/opt目录的内容同步至其他主机
files='
plan
baseconfig.sh
'
for file in $files;do
ansible 'all:!admin' -m synchronize -a "src=/opt/$file dest=/opt/$file"
ansible 'all' -m shell -a "chmod 600 /opt/$file"
done

ansible all -m shell -a "bash /opt/baseconfig.sh"
```
# 2. 先决条件
## 2.1 拉取镜像

```
apt update &> /dev/null 
apt install git python3-dev libffi-dev gcc libssl-dev python3-venv -y &> /dev/null

venv_path=/usr/local/kolla
if [[ ! -e $venv_path ]];then
mkdir -p $venv_path
python3 -m venv $venv_path
source $venv_path/bin/activate
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple  &> /dev/null
pip install -U pip &> /dev/null
fi

python3 -m pip install kolla &> /dev/null
python3 -m pip install docker &> /dev/null

public_registry=docker.io
image_namespace=kolla
private_registry=registry.cn-hangzhou.aliyuncs.com
private_namespace=mgt
#2024.2 对应 ubuntu-noble
#2024.1 对应 ubuntu-jammy
openstack_release=2024.2
image_base_os=ubuntu-noble
image_list=`kolla-build -b ubuntu --openstack-release ${openstack_release} --list-images |awk  '{print $NF}'`
for image in $image_list;do
        docker pull $public_registry/$image_namespace/$image:$openstack_release-$image_base_os
        docker tag $public_registry/$image_namespace/$image:$openstack_release-$image_base_os $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
        docker push $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
        docker rmi  $public_registry/$image_namespace/$image:$openstack_release-$image_base_os
        docker rmi $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
done
deactivate
```

## 2.2 安装依赖

https://docs.openstack.org/kolla-ansible/2024.2/

```
apt update &> /dev/null 
apt install git python3-dev libffi-dev gcc libssl-dev python3-venv -y &> /dev/null

venv_path=/usr/local/kolla
if [[ ! -e $venv_path ]];then
mkdir -p $venv_path
python3 -m venv $venv_path
source $venv_path/bin/activate
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple  &> /dev/null
pip install -U pip &> /dev/null
pip install 'ansible-core>=2.16,<2.17.99' &> /dev/null
deactivate
fi

```
# 3. 安装`kolla-ansible`

```
venv_path=/usr/local/kolla
source $venv_path/bin/activate
#git clone --branch stable/2024.2 https://opendev.org/openstack/kolla-ansible
#pip install ./kolla-ansible &> /dev/null
pip install kolla-ansible==19.1.0 &> /dev/null
# Install Ansible Galaxy requirements
kolla-ansible install-deps &> /dev/null
if [ ! -e /etc/kolla ];then
	mkdir -p /etc/kolla
	chown $USER:$USER /etc/kolla
	cp -r $venv_path/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
	cp -r $venv_path/share/kolla-ansible/ansible/inventory/* /etc/kolla
fi
#生成密码文件/etc/kolla/passwords.yml
kolla-genpwd
cp /etc/kolla/passwords.yml /etc/kolla/passwords.yml.bak
deactivate
```

# 4. 修改配置文件

## 4.1 `globals.yml`

```
cat << EOF > /etc/kolla/globals.yml
node_config: "/etc/kolla"   
kolla_base_distro: "ubuntu"
openstack_release: "2024.2"
node_custom_config: "{{ node_config }}/config"
kolla_internal_vip_address: "172.16.250.110"
docker_registry: "registry.cn-hangzhou.aliyuncs.com"
docker_namespace: "mgt"
network_interface: "bond1"
neutron_external_interface: "bond3"
neutron_plugin_agent: "openvswitch"
enable_openstack_core: "yes"
enable_hacluster: "yes"
enable_haproxy: "yes"
enable_keepalived: "{{ enable_haproxy | bool }}"
#enable_cinder: "yes"
#enable_cinder_backend_nfs: "no"
#cinder_backend_ceph: "yes"
#cinder_volume_group: "cinder-volumes"
# Glance
#ceph_glance_user: "glance"
#ceph_glance_pool_name: "images"
# Cinder
#ceph_cinder_user: "cinder"
#ceph_cinder_pool_name: "volumes"
#ceph_cinder_backup_user: "cinder-backup"
#ceph_cinder_backup_pool_name: "backups"
# Nova
#ceph_nova_user: "{{ ceph_cinder_user }}"
#ceph_nova_pool_name: "vms"
nova_compute_virt_type: "kvm"
EOF
```

## 4.2 `multinode`

```
#清理默认配置
sed -i -e '/^control./d
/^network./d
/^compute./d
/^storage./d
/^monitoring./d' /etc/kolla/multinode
#添加控制,网络,计算,存储,监控
sed -i -e '
/^\[control\]/acontroller\[1:3\] ansible_user=root
/^\[network\]/acompute\[1:3\] ansible_user=root
/^\[compute\]/acompute\[1:3\] ansible_user=root
/^\[storage\]/astorage\[1:3\] ansible_user=root
/^\[monitoring\]/acontroller\[1:3\] ansible_user=root
' /etc/kolla/multinode
```

## 4.3 tls

```

cat >> /etc/kolla/globals.yml <<EOF
kolla_enable_tls_internal: "yes"
kolla_enable_tls_external: "yes"
kolla_enable_tls_backend: "yes"
kolla_copy_ca_into_containers: "yes"
kolla_admin_openrc_cacert: "/etc/ssl/certs/ca-certificates.crt"
## debian ubuntu
openstack_cacert: "/etc/ssl/certs/ca-certificates.crt"
## Rhel Rocky
## openstack_cacert: "/etc/pki/tls/certs/ca-bundle.crt"
libvirt_enable_sasl: "False"
EOF
```

# 5. 部署

安装依赖
```
#Docker 安装报错处理
sed -i 's#download.docker.com#mirrors.ustc.edu.cn/docker-ce#g' ~/.ansible/collections/ansible_collections/openstack/kolla/roles/docker/defaults/main.yml
#计算节点自动注册
sed -i "s/nova_compute_registration_fatal.*/nova_compute_registration_fatal: true/g" $venv_path/share/kolla-ansible/ansible/roles/nova-cell/defaults/main.yml
#nova-compute容器启动认证报错
sed -i "s/libvirt_enable_sasl.*/libvirt_enable_sasl: false/g" $venv_path/share/kolla-ansible/ansible/roles/nova-cell/defaults/main.yml
```

```
kolla-ansible certificates -i /etc/kolla/multinode
```

```
kolla-ansible bootstrap-servers -i /etc/kolla/multinode
```

前置检查

```
kolla-ansible prechecks -i /etc/kolla/multinode
```

开始部署
```
kolla-ansible deploy -i /etc/kolla/multinode
```

完成部署

```
kolla-ansible post-deploy -i /etc/kolla/multinode
```

验证配置
```
kolla-ansible validate-config -i /etc/kolla/multinode
```

安装 OpenStack CLI 客户端
```
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2024.2
```

使用客户端
```
venv_path=/usr/local/kolla
source $venv_path/bin/activate
source /etc/kolla/admin-openrc.sh
```

执行初始化
```
openstack network create  --share --external \
  --provider-physical-network physnet1 \
  --provider-network-type flat public1
  
START_IP_ADDRESS=172.16.252.1
END_IP_ADDRESS=172.16.252.100
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_GATEWAY=172.16.252.254
PROVIDER_NETWORK_CIDR=172.16.252.0/24
openstack subnet create --network public1 \
  --allocation-pool start=$START_IP_ADDRESS,end=$END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDR public1

openstack network create selfservice
DNS_RESOLVER=8.8.8.8
SELFSERVICE_NETWORK_GATEWAY=172.16.0.254
SELFSERVICE_NETWORK_CIDR=172.16.0.0/24
openstack subnet create --network selfservice \
  --dns-nameserver $DNS_RESOLVER --gateway $SELFSERVICE_NETWORK_GATEWAY \
  --subnet-range $SELFSERVICE_NETWORK_CIDR selfservice

openstack router create router
openstack router add subnet router selfservice
openstack router set router --external-gateway public1

openstack flavor create --id 0 --vcpus 1 --ram 1024 --disk 20 m1.nano

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default


PROVIDER_NET_ID=`openstack network list | awk '/ public1 / { print $2 }'`
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$PROVIDER_NET_ID  \
  --key-name mykey provider-instance

SELFSERVICE_NET_ID=`openstack network list | awk '/ selfservice / { print $2 }'`
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$SELFSERVICE_NET_ID  \
  --key-name mykey selfservice-instance

openstack server list

openstack floating ip create public1

```

# 6.详细配置项

## 6.1 `Compute`

```
nova_compute_virt_type: "kvm"
nova_compute_virt_type: "qemu"

libvirt_enable_sasl: "False"
libvirt_tls: "yes"
```

## 6.2 `Neutron`

```
enable_neutron_provider_networks: yes
enable_neutron_agent_ha: "yes"
neutron_external_interface: bond3
```
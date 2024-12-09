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
>6.参考文档: https://docs.openstack.org/kolla-ansible/2024.2/user/quickstart.html

## 1.1 域名解析

```
cat << 'EOF' > /opt/playbook
172.16.250.101 controller1.ait.lo controller1 1qaz#EDC
172.16.250.102 controller2.ait.lo controller2 1qaz#EDC
172.16.250.103 controller3.ait.lo controller3 1qaz#EDC
172.16.250.104 compute1.ait.lo compute1 1qaz#EDC
172.16.250.105 compute2.ait.lo compute2 1qaz#EDC
172.16.250.106 compute3.ait.lo compute3 1qaz#EDC
172.16.250.107 storage1.ait.lo storage1 1qaz#EDC
172.16.250.108 storage2.ait.lo storage2 1qaz#EDC
172.16.250.109 storage3.ait.lo storage3 1qaz#EDC
EOF

```

```
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

EOF
cat /opt/playbook |awk '{print $1" "$2" "$3}' >> /etc/hosts
```
## 1.2 apt源
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

## 1.3 ssh免密

```
apt -y install sshpass &> /dev/null

if [ ! -e /root/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N '' &> /dev/null
fi

hosts=`cat /opt/playbook |sort |uniq |awk '{print $1}' |xargs`
for host in $hosts;do
 os_password=`cat /opt/playbook|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@$host &> /dev/null
done
```

## 1.4 Ansible

```
apt -y install ansible &> /dev/null
cat << EOF > /opt/ansibe-hosts
[admin]
`cat /opt/playbook |sort |uniq |grep controller1 |awk '{print $1}'`
[controllers]
`cat /opt/playbook |sort |uniq |grep controller |awk '{print $1}'`
[computes]
`cat /opt/playbook |sort |uniq |grep compute |awk '{print $1}'`
[storages]
`cat /opt/playbook |sort |uniq |grep storage |awk '{print $1}'`
[ntpservers:children]
controllers
[ntpclients:children]
computes
storages
EOF
if [ ! -e /etc/ansible ];then
	mkdir -p /etc/ansible
fi
cat /opt/ansibe-hosts > /etc/ansible/hosts
ansible all -m ping
```

## 1.5 基础配置脚本

```
cat << 'EEOOFF' > /opt/baseconfig.sh
#!/bin/bash
set -ex
#主机名
hostip=`ip route | egrep -v "br|docker|default" | egrep "eth|ens|enp" |awk '{print $NF}'`
HostName=`cat /opt/playbook |grep $hostip |awk '{print $3}'`
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
cat /opt/playbook |awk '{print $1" "$2" "$3}' >> /etc/hosts
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
playbook
baseconfig.sh
'
for file in $files;do
ansible 'all:!admin' -m synchronize -a "src=/opt/$file dest=/opt/$file"
ansible 'all' -m shell -a "chmod 600 /opt/$file"
done

ansible all -m shell -a "bash /opt/baseconfig.sh"
```
# 2. 先决条件
## 2.1 docker镜像

查看维护的版本
```
https://github.com/openstack/kolla/branches
```
使用`-b`克隆指定版本
```
git clone -b stable/2024.2 https://github.com/openstack/kolla.git
```
获取docker镜像名称
```
ls -R kolla/docker/ |grep  ":" |awk -F "/" '{print $4}' |grep -Ev '^$' |awk -F ":" '{print $1}'
```
拉取镜像
```
images=`ls -R kolla/docker/ |grep  ":" |awk -F "/" '{print $4}' |grep -Ev '^$' |awk -F ":" '{print $1}'`
imgtag='2024.2-ubuntu-noble'
for i in $images;do
  docker pull kolla/$i:$imgtag
  docker tag kolla/$i:$imgtag registry.cn-hangzhou.aliyuncs.com/mgt/$i:$imgtag
  docker push registry.cn-hangzhou.aliyuncs.com/mgt/$i:$imgtag
  docker rmi registry.cn-hangzhou.aliyuncs.com/mgt/$i:$imgtag
  docker rmi kolla/$i:$imgtag
  done
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
pip3 install docker &> /dev/null
deactivate
fi

```
# 3. 安装`kolla-ansible`

```
venv_path=/usr/local/kolla
source $venv_path/bin/activate
git clone --branch stable/2024.2 https://opendev.org/openstack/kolla-ansible
pip install ./kolla-ansible &> /dev/null
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
openstack_release: "2024.02"
node_custom_config: "{{ node_config }}/config"
kolla_internal_vip_address: "198.51.100.110"
docker_registry: registry.cn-hangzhou.aliyuncs.com
docker_namespace: "mgt"
network_interface: "bond1"
neutron_external_interface: "bond3"
neutron_plugin_agent: "openvswitch"
enable_openstack_core: "yes"
enable_hacluster: "yes"
enable_haproxy: "yes"
enable_keepalived: "{{ enable_haproxy | bool }}"
enable_cinder: "yes"
enable_cinder_backend_nfs: "no"
cinder_backend_ceph: "yes"
cinder_volume_group: "cinder-volumes"
# Glance
ceph_glance_user: "glance"
ceph_glance_pool_name: "images"
# Cinder
ceph_cinder_user: "cinder"
ceph_cinder_pool_name: "volumes"
ceph_cinder_backup_user: "cinder-backup"
ceph_cinder_backup_pool_name: "backups"
# Nova
ceph_nova_user: "{{ ceph_cinder_user }}"
ceph_nova_pool_name: "vms"
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
#添加node1-node3至配置文件的控制,网络,计算,存储,监控
sed -i -e '
/^\[control\]/anode\[1:3\] ansible_user=root
/^\[network\]/anode\[1:3\] ansible_user=root
/^\[compute\]/anode\[1:3\] ansible_user=root
/^\[storage\]/anode\[1:3\] ansible_user=root
/^\[monitoring\]/anode\[1:3\] ansible_user=root
' /etc/kolla/multinode

```

# 5. 部署

部署预检测
```
kolla-ansible bootstrap-servers -i /etc/kolla/multinode

kolla-ansible prechecks -i /etc/kolla/multinode
#
```

开始部署
```
kolla-ansible deploy -i /etc/kolla/multinode
```

验证部署
```
kolla-ansible validate-config -i /etc/kolla/multinode
```

安装 OpenStack CLI 客户端
```
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2024.2

kolla-ansible post-deploy

/usr/local/kolla/share/kolla-ansible/init-runonce
```

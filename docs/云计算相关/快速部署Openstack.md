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

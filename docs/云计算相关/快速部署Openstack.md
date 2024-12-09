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

```
apt update
apt install git python3-dev libffi-dev gcc libssl-dev python3-venv -y

python3 -m venv /usr/local/kolla
source /usr/local/kolla/activate
pip config set global.index-url http://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
pip install -U pip
pip install 'ansible-core>=|ANSIBLE_CORE_VERSION_MIN|,<|ANSIBLE_CORE_VERSION_MAX|.99'
```
# 3. 安装`kolla-ansible`

```
git clone -b stable/2024.2 https://opendev.org/openstack/kolla-ansible.git
 
cd kolla-ansible

```

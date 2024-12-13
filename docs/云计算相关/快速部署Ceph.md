# 1. Cephadm

## 1.1 规划

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
>本文档针对storage1-3;前置文档[[快速部署Openstack]]
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
>参考文档:https://docs.ceph.com/en/latest/cephadm/>

## 1.2 先决条件

- Python 3    
- Systemd    
- Podman or Docker for running containers    
- Time synchronization    
- LVM2 for provisioning storage devices
### 1.2.1 bond配置
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
### 1.2.2 域名解析

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

### 1.2.4 ssh对等

```
apt update &> /dev/null && apt -y install sshpass  &> /dev/null
if [ ! -e /root/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
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

### 1.2.5 Ansible

```
apt -y install ansible &> /dev/null
cat << EOF > /opt/ansibe-hosts
[admin]
`cat /opt/plan |sort |uniq |grep storage1 |awk '{print $1}'`
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

### 1.2.6 基础配置脚本

```
cat << 'EEOOFF' > /opt/baseconfig.sh
#1.Hostname
mgmtnic=`ip route |grep default |awk '{print $(NF-2)}'`
hostip=`ip route |grep -Ev "br|docker|default" |grep $mgmtnic |awk '{print $NF}'`
HostName=`cat /opt/plan |grep $hostip |awk '{print $3}'`
hostnamectl set-hostname $HostName
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
apt install cephadm -y &> /dev/null
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
cat /opt/plan |awk '{print $1" "$2" "$3}' >> /etc/hosts

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
#apt install docker.io -y &> /dev/null
#7.关闭swap
swapoff -a
sed -i "s|/swap|#/swap|" /etc/fstab
#8.关闭非必要的系统服务
systemctl disable ufw apparmor --now
EEOOFF

files='
plan
baseconfig.sh
'
for f in $files;do
ansible 'all:!admin' -m synchronize -a "src=/opt/$f dest=/opt/$f"
done

ansible all -m shell -a "bash /opt/baseconfig.sh"
```

## 1.3 安装cephadm

```
apt install cephadm -y 
```

## 1.4 Ceph容器镜像

cephadm的版本并从官方镜像站下载镜像文件,最新版:[https://quay.io/repository/ceph/ceph](https://quay.io/repository/ceph/ceph)旧版本: [https://hub.docker.com/r/ceph](https://hub.docker.com/r/ceph)

```
apt show cephadm |grep Version |uniq |awk '{print $NF}' 
```

```
docker pull quay.io/ceph/ceph:v17.2.8
docker tag quay.io/ceph/ceph:v17.2.8 registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v17.2.8
docker push registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v17.2.8

docker pull registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v17.2.8
docker tag registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v17.2.8 quay.io/ceph/ceph:v17.2.8
```

```
docker pull quay.io/ceph/ceph:v19.2.0
docker tag quay.io/ceph/ceph:v19.2.0 registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v19.2.0
docker push registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v19.2.0

docker pull registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v19.2.0
docker tag  registry.cn-hangzhou.aliyuncs.com/mgt/ceph:v19.2.0 quay.io/ceph/ceph:v19.2.0
```
## 1.5  引导一个新集群

创建新 Ceph 集群的第一步是在 Ceph 集群的第一台主机上运行`cephadm bootstrap`命令。运行的行为 Ceph 集群第一台主机上的`cephadm bootstrap`命令创建 Ceph 集群的第一个 Monitor 守护进程。您必须将 Ceph 集群第一台主机的 IP 地址传递给`ceph bootstrap`命令，因此您需要知道该主机的 IP 地址。

```
if [ ! -e /root/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
fi
cephadm bootstrap --mon-ip 172.16.254.107
```
运行结果:
- 在本地主机上为新集群创建监视器和管理器守护程序。
- 为 Ceph 集群生成新的 SSH 密钥并将其添加到 root 用户的`/root/.ssh/authorized_keys`文件中。
- 将公钥的副本写入`/etc/ceph/ceph.pub` 。
- 将最小配置文件写入`/etc/ceph/ceph.conf` 。需要此文件与 Ceph 守护进程进行通信。
- 将`client.admin`管理（特权！）密钥的副本写入 `/etc/ceph/ceph.client.admin.keyring` 。
- 将`_admin`标签添加到引导主机。默认情况下，任何具有此标签的主机都将（也）获得`/etc/ceph/ceph.conf`的副本，并且 `/etc/ceph/ceph.client.admin.keyring` .
高级选项:
- 默认情况下，Ceph 守护进程将其日志输出发送到 stdout/stderr，该日志输出由容器运行时（docker 或 podman）拾取并（在大多数系统上）发送到 Journald。如果您希望 Ceph 将传统日志文件写入`/var/log/ceph/$fsid` ，请在引导期间使用`--log-to-file`选项。
- 当（Ceph 集群外部）公共网络流量与（Ceph 集群内部）集群流量分开时，较大的 Ceph 集群性能最佳。内部集群流量处理 OSD 守护进程之间的复制、恢复和心跳。您可以通过向`bootstrap`提供`--cluster-network`选项来定义[集群网络](https://docs.ceph.com/en/reef/rados/configuration/network-config-ref/#cluster-network) 子命令。该参数必须是 CIDR 表示法中的子网（例如 `10.90.90.0/24`或`fe80::/64` ）
- `cephadm bootstrap`写入访问新集群所需的`/etc/ceph`文件。这个中心位置使得安装在主机上的 Ceph 软件包（例如，可以访问 cephadm 命令行界面的软件包）可以找到这些文件。
- 然而，使用 cephadm 部署的守护进程容器不需要 `/etc/ceph`根本没有。使用`--output-dir *<directory>*`选项将它们放在不同的目录中（例如， `.` ）。这可能有助于避免与同一主机上的现有 Ceph 配置（cephadm 或其他）发生冲突。
- 您可以将任何初始 Ceph 配置选项传递到新集群，方法是将它们放入标准 ini 样式配置文件中并使用`--config *<config-file>*`选项。例如：
```
cat <<EOF > initial-ceph.conf
[global]
osd crush chooseleaf type = 0
EOF
$ ./cephadm bootstrap --config initial-ceph.conf ...
```
- `--ssh-user *<user>*`选项可以指定 cephadm 将使用哪个 SSH 用户连接到主机。关联的 SSH 密钥将添加到 `/home/*<user>*/.ssh/authorized_keys` 。您使用此选项指定的用户必须具有无密码 sudo 访问权限。
- 如果您使用来自需要登录的注册表的容器映像，则可以添加参数：- `--registry-json <path to json file>`,包含登录信息的 JSON 文件的示例内容：
```
{"url":"REGISTRY_URL", "username":"REGISTRY_USERNAME", "password":"REGISTRY_PASSWORD"}
```
- Cephadm 将尝试登录到此注册表，以便它可以拉取您的容器，然后将登录信息存储在其配置数据库中。添加到集群的其他主机也将能够使用经过身份验证的容器注册表。

```
root@node1:~# cephadm bootstrap --mon-ip 198.19.33.111
This is a development version of cephadm.
For information regarding the latest stable release:
    https://docs.ceph.com/docs/squid/cephadm/install
Creating directory /etc/ceph for ceph.conf
Verifying podman|docker is present...
Verifying lvm2 is present...
Verifying time synchronization is in place...
Unit chrony.service is enabled and running
Repeating the final host check...
docker (/usr/bin/docker) is present
systemctl is present
lvcreate is present
Unit chrony.service is enabled and running
Host looks OK
Cluster fsid: 1c581fea-b391-11ef-a138-000c296ec16b
Verifying IP 198.19.33.111 port 3300 ...
Verifying IP 198.19.33.111 port 6789 ...
Mon IP `198.19.33.111` is in CIDR network `198.19.33.0/24`
Mon IP `198.19.33.111` is in CIDR network `198.19.33.0/24`
Internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
Pulling container image quay.io/ceph/ceph:v19...
Ceph version: ceph version 19.2.0 (16063ff2022298c9300e49a547a16ffda59baf13) squid (stable)
Extracting ceph user uid/gid from container image...
Creating initial keys...
Creating initial monmap...
Creating mon...
Waiting for mon to start...
Waiting for mon...
mon is available
Assimilating anything we can from ceph.conf...
Generating new minimal ceph.conf...
Restarting the monitor...
Setting public_network to 198.19.33.0/24 in mon config section
Wrote config to /etc/ceph/ceph.conf
Wrote keyring to /etc/ceph/ceph.client.admin.keyring
Creating mgr...
Verifying port 0.0.0.0:9283 ...
Verifying port 0.0.0.0:8765 ...
Verifying port 0.0.0.0:8443 ...
Waiting for mgr to start...
Waiting for mgr...
mgr not available, waiting (1/15)...
mgr not available, waiting (2/15)...
mgr not available, waiting (3/15)...
mgr not available, waiting (4/15)...
mgr not available, waiting (5/15)...
mgr is available
Enabling cephadm module...
Waiting for the mgr to restart...
Waiting for mgr epoch 5...
mgr epoch 5 is available
Setting orchestrator backend to cephadm...
Generating ssh key...
Wrote public SSH key to /etc/ceph/ceph.pub
Adding key to root@localhost authorized_keys...
Adding host node1...
Deploying mon service with default placement...
Deploying mgr service with default placement...
Deploying crash service with default placement...
Deploying ceph-exporter service with default placement...
Deploying prometheus service with default placement...
Deploying grafana service with default placement...
Deploying node-exporter service with default placement...
Deploying alertmanager service with default placement...
Enabling the dashboard module...
Waiting for the mgr to restart...
Waiting for mgr epoch 9...
mgr epoch 9 is available
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
Ceph Dashboard is now available at:

             URL: https://node1.ait.lo:8443/
            User: admin
        Password: etxkbspky4

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/1c581fea-b391-11ef-a138-000c296ec16b/config directory
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

        sudo /usr/sbin/cephadm shell --fsid 1c581fea-b391-11ef-a138-000c296ec16b -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

        sudo /usr/sbin/cephadm shell 

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/en/latest/mgr/telemetry/

Bootstrap complete.
```

admin 密码修改为1qaz#EDC
## 1.6 启用ceph cli

Cephadm 不需要在主机上安装任何 Ceph 软件包。但是，我们建议启用对`ceph`轻松访问 命令。有几种方法可以做到这一点：
- `cephadm shell`命令在安装了所有 Ceph 软件包的容器中启动 bash shell。默认情况下，如果在`/etc/ceph`中找到配置和密钥环文件 主机，它们被传递到容器环境中，以便 shell 功能齐全。请注意，当在 MON 主机上执行时， `cephadm shell`将从 MON 容器推断`config`而不是使用默认配置。如果`--mount <path>` 给定后，主机`<path>` （文件或目录）将出现在容器内的`/mnt`下：
交互式
```
cephadm shell
ceph -s
```
非交互式
```
cephadm shell -- ceph -s
```
- 您可以安装`ceph-common`软件包，其中包含所有 ceph 命令，包括`ceph` 、 `rbd` 、 `mount.ceph` （用于挂载 CephFS 文件系统）等：
```
cephadm install ceph-common
ceph -v
ceph status

ansible all -m shell -a 'apt install cephadm -y'
ansible all -m shell -a 'cephadm install ceph-common'
```

查看组件状态

```
alias ceph='cephadm shell -- ceph'
echo "alias ceph='cephadm shell -- ceph'" >>/root/.bashrc
source /root/.bashrc

ceph orch ps
ceph status
ceph -v
ceph orch host ls
```

>[!NOTE]
>添加管理主机
默认情况下， `ceph.conf`文件和`client.admin`密钥环的副本保存在所有具有`_admin`标签的主机上的`/etc/ceph`中。该标签最初仅应用于引导主机。我们建议为一台或多台其他主机指定`_admin`标签，以便可以在多台主机上轻松访问 Ceph CLI（例如，通过`cephadm shell` ）。要将`_admin`标签添加到其他主机，请运行以下形式的命令：
>`ceph orch host label add *<host>* _admin`

## 1.7 主机操作

### 1.7.1 向群集中添加主机

分发密钥
```
hosts='
172.16.250.107
172.16.250.108
172.16.250.109
'
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id -f -i /etc/ceph/ceph.pub  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

hosts='
storage1
storage2
storage3
'
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id -f -i /etc/ceph/ceph.pub  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

hosts='
storage1.test.local
storage2.test.local
storage3.test.local
'
for host in $hosts;do
 os_password=`cat /opt/plan|sort |uniq |grep $host |awk '{print $NF}'`
 sshpass -p ${os_password}  ssh-copy-id -f -i /etc/ceph/ceph.pub  -o StrictHostKeyChecking=no root@$host &> /dev/null
done

hosts='
172.16.254.107
172.16.254.108
172.16.254.109
'
for host in $hosts;do
 os_password='1qaz#EDC'
 sshpass -p ${os_password}  ssh-copy-id -f -i /etc/ceph/ceph.pub  -o StrictHostKeyChecking=no root@$host &> /dev/null
done
```

```
ceph orch apply mon 5
ceph orch host add storage2 172.16.254.108 --labels _admin
ceph orch host add storage3 172.16.254.109 --labels _admin

ceph orch host label add node2  _admin
ceph orch host label add node3  _admin
```

```
ceph orch host ls
ceph orch ps
```

```
cat > /opt/ceph_hosts <<EOF
service_type: host
addr: 172.16.254.107
hostname: storage1
labels:
- mon
- osd
- mgr
---
service_type: host
addr: 172.16.254.108
hostname: storage2
labels:
- mon
- osd
- mgr
---
service_type: host
addr: 172.16.254.109
hostname: storage3
labels:
- mon
- osd
- mgr
EOF
ceph orch apply -i /opt/ceph_hosts
```

### 1.7.2 删除主机

```
ceph orch host drain node2  #删除守护进程
ceph orch osd rm status #删除osd
ceph orch ps node2
ceph orch host rm node2
ceph orch host rm node2 --offline --force #删除离线主机
```

>[!note]
>## 主机标签
>1. `_no_schedule` ：_不在该主机上调度或部署守护程序_
>2. `_no_conf_keyring` ：_不要在此主机上部署配置文件或密钥环_。
>3. `_no_autotune_memory` ：_不自动调整该主机上的内存_。
>4. `_admin` ：_将 client.admin 和 ceph.conf 分发到该主机_。

### 1.7.3 维护模式

```
ceph orch host maintenance enter <hostname> [--force] [--yes-i-really-mean-it]
ceph orch host maintenance exit <hostname>

```

### 1.7.4 重新扫描主机

```
ceph orch host rescan <hostname> [--with-summary]
```
## 1.8 添加额外的 MON

典型的 Ceph 集群具有三到五个分布在不同主机上的 Monitor 守护进程。如果集群中有五个或更多节点，我们建议部署五个监视器。大多数集群不会从七个或更多监视器中受益。
随着集群的增长，Ceph 会自动部署监控守护进程，而随着集群的收缩，Ceph 会自动缩减监控守护进程。这种自动增长和收缩的顺利执行取决于正确的子网配置。
cephadm 引导过程将集群中的第一个监视器守护进程分配给特定子网。 `cephadm`将该子网指定为集群的默认子网。默认情况下，新的监视器守护进程将分配给该子网，除非 cephadm 收到其他指示。
如果集群中的所有 ceph 监控守护进程都位于同一子网中， 无需手动管理 ceph 监视器守护进程。 当新主机添加到集群时， `cephadm`将根据需要自动向子网添加最多五个监视器。

```
ceph orch apply mon 3
ceph orch apply mon --placement="storage1,storage2,storage3" --dry-run
ceph orch apply mon --placement="storage1,storage2,storage3"
```

```
cat > /opt/mon.yaml <<EOF
service_type: mon
placement:
  hosts:
    - storage1
    - storage2
    - storage3
EOF
ceph orch apply -i /opt/mon.yaml
```
### 1.8.1 为监视器指定特定子网

要指定 ceph 监控守护进程使用的特定 IP 子网，请使用以下形式的命令，包括[CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation)中的子网地址 格式（例如`10.1.2.0/24` ）：

```
ceph config set mon public_network 10.1.2.0/24
```

您还可以使用网络列表指定两个公共网络：

```
ceph config set mon public_network 10.1.2.0/24,192.168.0.1/24
```

### 1.8.2在特定网络上部署监视器

您可以为每个显示器显式指定 IP 地址或 CIDR 网络，并控制每个显示器的放置位置。要禁用自动监视器部署，请运行以下命令：

```
ceph orch apply mon --unmanaged
```

### 1.8.3 要部署每个附加监视器：

例如，要使用 IP 地址`10.1.2.123`在`newhost1`上部署第二个监视器，并在网络`10.1.2.0/24`中的`newhost2`上部署第三个监视器，请运行以下命令：

```
ceph orch apply mon --unmanaged
ceph orch daemon add mon newhost1:10.1.2.123
ceph orch daemon add mon newhost2:10.1.2.0/24
ceph orch apply mon --placement="newhost1,newhost2,newhost3" --dry-run
ceph orch apply mon --placement="newhost1,newhost2,newhost3"
```

### 1.8.4 将监视器移至不同网络

例如，要使用 IP 地址`10.1.2.123`在`newhost1`上部署第二个监视器，并在网络`10.1.2.0/24`中的`newhost2`上部署第三个监视器，请运行以下命令

```
ceph orch apply mon --unmanaged
ceph orch daemon add mon newhost1:10.1.2.123
ceph orch daemon add mon newhost2:10.1.2.0/24

ceph orch daemon rm *mon.<oldhost1>*

ceph config set mon public_network 10.1.2.0/24
ceph orch apply mon --placement="newhost1,newhost2,newhost3" --dry-run
ceph orch apply mon --placement="newhost1,newhost2,newhost3"
```

## 1.9 部署mgr

```
ceph orch apply mgr 3
ceph orch apply mgr --placement="storage1,storage2,storage3" --dry-run
ceph orch apply mgr --placement="storage1,storage2,storage3"
ceph orch ps |grep mgr

```

```
ceph orch apply alertmanager 3
ceph orch apply prometheus 3
ceph orch apply grafana 3
```
## 1.10 部署osd

```
ceph config set mgr mgr/cephadm/device_enhanced_scan true

lsmcli ldl
ceph orch device ls

ceph orch apply osd --all-available-devices --dry-run
ceph orch apply osd --all-available-devices

ceph orch daemon add osd storage1:/dev/sdb
ceph orch daemon add osd storage2:/dev/sdb
ceph orch daemon add osd storage3:/dev/sdb

ceph orch daemon add osd storage1:/dev/sdc
ceph orch daemon add osd storage2:/dev/sdc
ceph orch daemon add osd storage3:/dev/sdc

ceph orch osd rm status
```
从特定主机上的特定设备创建 OSD：
```
ceph orch daemon add osd node1:/dev/sdb
```
从特定主机上的特定设备创建高级 OSD：
```
ceph orch daemon add osd host1:data_devices=/dev/sda,/dev/sdb,db_devices=/dev/sdc,osds_per_device=2
```
在特定主机上的特定LVM逻辑卷上创建OSD：
```
ceph orch daemon add osd host1:/dev/vg_osd/lvm_osd1701
```
您可以使用[高级 OSD 服务规范](https://docs.ceph.com/en/reef/cephadm/services/osd/#drivegroups)根据设备的属性对设备进行分类。这可能有助于更清晰地了解哪些设备可供使用。属性包括设备类型（SSD 或 HDD）、设备型号名称、大小以及设备所在的主机：
```
ceph orch apply -i spec.yml
```

```
ceph orch osd rm status
```
## 1.11 使用ceph

### 1.11.1 部署cephfs

```

```

### 1.11.2  部署RGW

```
ceph orch apply rgw myrgw
ceph orch host label add storage1 rgw # the 'rgw' label can be anything
ceph orch host label add storage2 rgw  
ceph orch host label add storage3 rgw
ceph orch apply rgw myrgw '--placement=label:rgw count-per-host:2' --port=8000


```

```
radosgw-admin realm create --rgw-realm=test_realm --default
radosgw-admin zonegroup create --rgw-zonegroup=default  --master --default
radosgw-admin zone create --rgw-zonegroup=default --rgw-zone=test_zone --master --default
radosgw-admin period update --rgw-realm=test_realm --commit
ceph orch apply rgw test --realm=test_realm --zone=test_zone --placement="2 storage1 storage2 storage3"

```

高可用
```
cat > /opt/myrgw.yaml <<EOF
service_type: rgw
service_id: myrgw
placement:
  count_per_host: 2
  hosts:
    - storage1
    - storage2
    - storage3
networks:
- 172.16.254.0/24
spec:
  rgw_frontend_port: 8000
EOF
ceph orch apply -i /opt/myrgw.yaml

cat > /opt/hargw.yaml <<EOF
service_type: ingress
service_id: rgw.myrgw    # adjust to match your existing RGW service Name
placement:
  hosts:
    - storage1
    - storage2
    - storage3
spec:
  backend_service: rgw.myrgw   # adjust to match your existing RGW service Name
  virtual_ips_list:
    - 172.16.254.100              
  frontend_port: 8100            
  monitor_port: 8765
  virtual_interface_networks: 
    - 172.16.254.0/24
  #first_virtual_router_id: <integer>  # optional: default 50
  #health_check_interval: <string>     # optional: Default is 2s.
  #ssl_cert: |                         # optional: SSL certificate and key
EOF
ceph orch apply -i /opt/hargw.yaml
```
### 1.11.3 部署NFS

```

```
### 1.11.4 部署iscsi

```

```
## 1.12 对接openstack

在生产环境中，我们经常能够看见将Nova、Cinder、Glance与Ceph RBD进行对接。除此之外，还可以将Swift、Manila分别对接到Ceph RGW与CephFS。Ceph作为统一存储解决方案，有效降低了OpenStack云环境的复杂性与运维成本。
### 1.12.1 先决条件

https://docs.ceph.com/en/latest/rbd/rbd-openstack/

创建和初始化RBD存储池
- images 对接 glance
- vms对接nova
- volumes对接cinder
- backups对接cinder-bakup
```
ceph osd pool create images
ceph osd pool create vms
ceph osd pool create volumes
ceph osd pool create backups
rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms
```

创建ceph用户

| 用户名                  | 访问权限               | 备注                         |
| -------------------- | ------------------ | -------------------------- |
| client.glance        | images             | controller,storage         |
| client.cinder        | images vms volumes | controller,compute,storage |
| client.cinder-backup | backups            | controller,storage         |

```
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children,allow rwx pool=images'

ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images'

ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups'

```

查看用户信息
```
ceph auth list
```

分发keyring和配置文件

```
#在存储部署节点上操作
ceph config generate-minimal-conf |ssh root@172.16.250.101 tee  /etc/ceph/ceph.conf

#ceph.conf分发至计算和控制节点
sed -i '/^#/d' /etc/ceph/ceph.conf
sed -i 's/\t//g' /etc/ceph/ceph.conf
ansible 'controllers:computes:storages' -m synchronize -a "src=/etc/ceph/ceph.conf dest=/etc/ceph/ceph.conf"
ansible 'controllers:!admin' -m synchronize -a "src=/etc/ceph/ceph.client.admin.keyring dest=/etc/ceph/ceph.client.admin.keyring"
#用于glance-api,分发至控制节点,存储节点(cinder-volume)
ceph auth get-or-create client.glance > /etc/ceph/ceph.client.glance.keyring
ansible 'controllers:storages' -m synchronize -a "src=/etc/ceph/ceph.client.glance.keyring dest=/etc/ceph/ceph.client.glance.keyring"
#用于cinder,分发至控制节点,计算节点,存储节点
ceph auth get-or-create client.cinder > /etc/ceph/ceph.client.cinder.keyring
ansible 'controllers:computes:storages' -m synchronize -a "src=/etc/ceph/ceph.client.cinder.keyring dest=/etc/ceph/ceph.client.cinder.keyring"
#用于cinder-backup,分发至控制节点,存储节点
ceph auth get-or-create client.cinder-backup >  /etc/ceph/ceph.client.cinder-backup.keyring
ansible 'controllers:storages' -m synchronize -a "src=/etc/ceph/ceph.client.cinder-backup.keyring dest=/etc/ceph/ceph.client.cinder-backup.keyring"
#用于nova-compute,分发至计算节点
ceph auth get-key  client.cinder > /etc/ceph/ceph.client.cinder.key
ansible 'computes' -m synchronize -a "src=/etc/ceph/ceph.client.cinder.key dest=/etc/ceph/ceph.client.cinder.key"

#ansible 'computes:controllers' -m shell -a "chown glance:glance /etc/ceph/ceph.client.glance.keyring"
#ansible 'controllers:computes' -m shell -a "chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring"
#ansible controllers -m shell -a "chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring"

```

```
ceph orch client-keyring ls
```

### 1.12.2 Openstack侧

```
cat << EOF > /etc/kolla/globals.yml
node_config: "/etc/kolla"   
kolla_base_distro: "ubuntu"
openstack_release: "2024.2"
node_custom_config: "{{ node_config }}/config"
kolla_internal_vip_address: "172.16.250.110"
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
#cinder_volume_group: "cinder-volumes"
# Glance
glance_backend_ceph: "yes"
ceph_glance_user: "glance"
ceph_glance_pool_name: "images"
# Cinder
cinder_cluster_name: "cinder-cluster01"
cinder_backend_ceph: "yes"
ceph_cinder_user: "cinder"
ceph_cinder_pool_name: "volumes"
ceph_cinder_backup_user: "cinder-backup"
ceph_cinder_backup_pool_name: "backups"
# Nova
nova_backend_ceph: "yes"
ceph_nova_user: "{{ ceph_cinder_user }}"
ceph_nova_pool_name: "vms"
nova_compute_virt_type: "kvm"
EOF
```
glance
```
if [ ! -e /etc/kolla/config/glance ];then
	mkdir -p /etc/kolla/config/glance
fi
cat /etc/ceph/ceph.conf > /etc/kolla/config/glance/ceph.conf
cat /etc/ceph/ceph.client.glance.keyring > /etc/kolla/config/glance/ceph.client.glance.keyring

cat << EOF >> /etc/kolla/config/glance/ceph.conf
keyring = /etc/ceph/ceph.client.glance.keyring
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
EOF
cat << EOF > /etc/kolla/config/glance.conf
[DEFAULT]
show_image_direct_url = True
EOF

```
Cinder
```
if [ ! -e /etc/kolla/config/cinder ];then
	mkdir -p /etc/kolla/config/cinder
fi
cat /etc/ceph/ceph.conf > /etc/kolla/config/cinder/ceph.conf

if [ ! -e /etc/kolla/config/cinder/cinder-volume ];then
	mkdir -p /etc/kolla/config/cinder/cinder-volume
fi
cat /etc/ceph/ceph.client.cinder.keyring > /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring 

if [ ! -e /etc/kolla/config/cinder/cinder-backup ];then
	mkdir -p /etc/kolla/config/cinder/cinder-backup
fi
cat /etc/ceph/ceph.client.cinder.keyring > /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring 
cat /etc/ceph/ceph.client.cinder-backup.keyring > /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring

cat << EOF >> /etc/kolla/config/cinder/ceph.conf
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
EOF

if [ ! -e /etc/kolla/config/nova ];then
	mkdir -p /etc/kolla/config/nova
fi
cat /etc/ceph/ceph.client.cinder.keyring > /etc/kolla/config/nova/ceph.client.cinder.keyring

```
Nova
```
if [ ! -e /etc/kolla/config/nova ];then
	mkdir -p /etc/kolla/config/nova
fi
cat /etc/ceph/ceph.conf > /etc/kolla/config/nova/ceph.conf
cat /etc/ceph/ceph.client.cinder.keyring > /etc/kolla/config/nova/ceph.client.cinder.keyring
cat << EOF >> /etc/kolla/config/nova/ceph.conf
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
EOF
sed -i 's/\t//g' /etc/kolla/config/nova/ceph.conf 
```

验证
```
#glance api
openstack image create --file cirros-0.6.2-x86_64-disk.img cirros2
rbd ls images

rbd snap ls images/`rbd ls images`
rbd info images/`rbd ls images`
rados ls -p images

#cinder
openstack volume service list


SELFSERVICE_NET_ID=`openstack network list | awk '/ selfservice / { print $2 }'`
openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$SELFSERVICE_NET_ID \
  --key-name mykey selfservice-instance2

openstack volume create --size 1 volume1

INSTANCE_NAME=selfservice-instance2
VOLUME_NAME=volume1
openstack server add volume $INSTANCE_NAME $VOLUME_NAME

```
# 2. Rook
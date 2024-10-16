# 1. 修改apt源

```
#!/bin/bash
echo '# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources' > /etc/apt/sources.list
cat << EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://${SERVER_IP}/ubuntu
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates ${VERSION_CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://${SERVER_IP}/ubuntu
Suites: ${VERSION_CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```
# 2. IP地址配置

```
#!/bin/bash
rm -rf /etc/netplan/*

get_active_netdev_names() {
	All_NICs=$(lshw -C network -businfo  |awk '/(E|e)thernet (C|c)ontroller/{print $2}' |xargs)
	for i in ${All_NICs}
	do
		if ip link show $i |grep LOWER_UP &> /dev/null
		then
				echo $i
		fi
	done	
}

NIC=$(get_active_netdev_names |xargs)
#等价于
#NIC=`get_active_netdev_names |xargs`
for n in ${NIC[*]}
do
cat  >/etc/netplan/${n}.yaml <<EOF
network:
  ethernets:
    ${n}:
      dhcp4: false
      dhcp6: false
      addresses:
EOF
	for i in `ip add show dev ${n}|egrep "inet "|awk '{print $2}'`
	do
	cat  >>/etc/netplan/${n}.yaml <<EOF
        - ${i}
EOF
	done
	if [ ${n} == `ip route|egrep "default" | awk '{print $5}'` ]
	then
	DFGW=`ip route|egrep "default" | awk '{print $3}'`
	cat  >>/etc/netplan/${n}.yaml <<-EOF
      routes:
        - to: default
          via: ${DFGW}
EOF
	fi
cat >>/etc/netplan/${n}.yaml	<<'EOF'
      nameservers:
        addresses:
          - 114.114.114.114
          - 8.8.8.8
EOF
done
netplan apply
```
# 3. ssh对等

```
get_os_type() {
if [ ! -e /etc/os-release ];then
  echo 'Unable get linux distribution !'
fi
source /etc/os-release
echo $ID
}
case $(get_os_type) in
	anolis|kylin|openEuler )
		yum install sshpass -y 
		;;
	debian|ubuntu )
		apt update
		export DEBIAN_FRONTEND=noninteractive
		apt install sshpass -y 
		;;
esac
if [ ! -e ~/.ssh/id_rsa ];then
	ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''
fi
os_password='passowrd'
os_hostname='
192.168.1.1
192.168.1.2
192.168.1.10
'
for i in ${os_hostname};do
	sshpass -p ${os_password}  ssh-copy-id  -o StrictHostKeyChecking=no root@${i}
done
```
# 4. 时间同步

```

```
# 5. 远程运行脚本

```

```

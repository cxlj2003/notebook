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
declare -a NIC
NIC=`ip route | egrep -v "br|docker|default" | egrep "eth|ens|enp"|awk '{print $3}'` 
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
# 3. 

```

```

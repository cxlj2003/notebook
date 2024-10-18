# 1. 修改apt源
## 1.1 `sources.list`格式
```
#!/bin/bash
mirrors_server='mirrors.ustc.edu.cn'
source /etc/os-release
rm -rf /etc/apt/sources.list.d/*.sources

if [ ${ID} = ubuntu ];then
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
elif [ ${ID} = debian ];then
cat << EOF > /etc/apt/sources.list
deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main contrib
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME} main contrib

deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main contrib
deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-updates main contrib 

#deb http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main contrib
#deb-src http://${mirrors_server}/${ID}/ ${VERSION_CODENAME}-backports main contrib 

deb http://${mirrors_server}/${ID}-security/ ${VERSION_CODENAME}-security main contrib
deb-src http://${mirrors_server}/${ID}-security/ ${VERSION_CODENAME}-security main contrib 
EOF
fi
```

## 1.2 `DEB822`格式
```
#!/bin/bash
mirrors_server='mirrors.ustc.edu.cn'
source /etc/os-release
echo "# ${ID} sources have moved to /etc/apt/sources.list.d/${ID}.sources" > /etc/apt/sources.list
if [ ${ID} = ubuntu ];then
cat << EOF > /etc/apt/sources.list.d/${ID}.sources
Types: deb
URIs: http://${mirrors_server}/${ID}
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates ${VERSION_CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/${ID}-archive-keyring.gpg

Types: deb
URIs: http://${mirrors_server}/${ID}
Suites: ${VERSION_CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/${ID}-archive-keyring.gpg
EOF
elif [ ${ID} = debian ];then
cat << EOF > /etc/apt/sources.list.d/${ID}.sources
Types: deb
URIs: http://${mirrors_server}/${ID}
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates
Components: main contrib non-free
Signed-By: /usr/share/keyrings/${ID}-archive-keyring.gpg

Types: deb
URIs: http://${mirrors_server}/${ID}-security
Suites: ${VERSION_CODENAME}-security
Components: main contrib non-free
Signed-By: /usr/share/keyrings/${ID}-archive-keyring.gpg
EOF
fi
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

# 6.openEuler跨版本升级

```
src_version='openEuler-20.03-LTS-SP4'
dst_version='openEuler-24.03-LTS'
cp /etc/yum.repos.d/openEuler.repo /etc/yum.repos.d/openEuler.repo.bak
sed -i -e '/metalink/d' -e '/metadata_expire/d' /etc/yum.repos.d/openEuler.repo
sed -i "s/${src_version}/${dst_version}/g" /etc/yum.repos.d/openEuler.repo
yum clean all
yum update --allowerasing -y
yum autoremove -y
yum reinstall systemd -y

```

```
src_version='openEuler-22.03-LTS-SP4'
dst_version='openEuler-24.03-LTS'
cp /etc/yum.repos.d/openEuler.repo /etc/yum.repos.d/openEuler.repo.bak
sed -i -e '/metalink/d' -e '/metadata_expire/d' /etc/yum.repos.d/openEuler.repo
sed -i "s/${src_version}/${dst_version}/g" /etc/yum.repos.d/openEuler.repo
yum clean all 
yum update --allowerasing -y
yum autoremove -y
yum reinstall systemd -y

```

# 7. Debian跨版本升级

```
#!/bin/bash
RELEASE=$(cat /etc/issue)

__do_apt_update(){
    apt update
    if [ $? -ne 0 ]; then
        exit 1
    fi;
}

__do_apt_upgrade(){
    __do_apt_update
    apt upgrade -y
    apt dist-upgrade -y
    apt full-upgrade -y
}

__do_debian10_upgrade(){
    echo "[INFO] Doing debian 10 upgrade..."
    __do_apt_upgrade
    sed -i 's/stretch/buster/g' /etc/apt/sources.list
    sed -i 's/stretch/buster/g' /etc/apt/sources.list.d/*.list
    __do_apt_upgrade
    echo "[INFO] Please reboot"
}

__do_debian11_upgrade(){
    echo "[INFO] Doing debian 11 upgrade..."
    __do_apt_upgrade
    sed -i 's/buster/bullseye/g' /etc/apt/sources.list
    sed -i 's/buster/bullseye/g' /etc/apt/sources.list.d/*.list
    sed -i 's/bullseye\/updates/bullseye-security/g' /etc/apt/sources.list
    __do_apt_upgrade
    echo "[INFO] Please reboot"
}

__do_debian12_upgrade(){
    echo "[INFO] Doing debian 12 upgrade..."
    __do_apt_upgrade
    sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
    sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list.d/*.list
    sed -i 's/bullseye-security/bullseye-bookworm/g' /etc/apt/sources.list
    __do_apt_upgrade
    echo "[INFO] Please reboot"
}


echo $RELEASE | grep ' 9 '
if [ $? -eq 0 ]; then
    __do_debian10_upgrade
    exit 0
fi;

echo $RELEASE | grep ' 10 '
if [ $? -eq 0 ]; then
    __do_debian11_upgrade
    exit 0
fi;

echo $RELEASE | grep ' 11 '
if [ $? -eq 0 ]; then
    __do_debian12_upgrade
    exit 0
fi;
```

```
#!/bin/bash -e
source /etc/os-release

__get_stable_release(){
  if which curl ;then
    stable_release=$(curl -s https://www.debian.org/releases/stable/index.html |awk -F \;  '/Release Information <\/title>/{print $(NF-1)}' |cut -d \& -f 1)
  elif which wget ; then
  	rm -f /tmp/index.html
  	wget -q -P /tmp/ https://www.debian.org/releases/stable/index.html
    stable_release=$(cat /tmp/index.html | awk -F \;  '/Release Information <\/title>/{print $(NF-1)}' |cut -d \& -f 1)
    rm -f /tmp/index.html
  fi
  }

__do_apt_update(){
    sed -i '/deb cdrom/d' /etc/apt/sources.list
    if [ $(ls /etc/apt/sources.list.d |wc -l) -gt 0 ];then
	    sed -i '/deb cdrom/d' /etc/apt/sources.list.d/*.list
	  fi
    apt update
    export DEBIAN_FRONTEND=noninteractive
    if [ $? -ne 0 ];then
      #exit 1
      echo 1
    fi
  }
  
__do_apt_upgrade(){
  __do_apt_update
  apt upgrade -y
  apt dist-upgrade -y
  apt full-upgrade -y
  }

__do_release_upgrade(){
  __get_stable_release
  __do_apt_upgrade
  sed -i "s/${VERSION_CODENAME}/${stable_release}/g" /etc/apt/sources.list
  sed -i 's#/updates#-updates#g' /etc/apt/sources.list
  if [ $(ls /etc/apt/sources.list.d |wc -l) -gt 0 ];then
	  sed -i "s/${VERSION_CODENAME}/${stable_release}/g" /etc/apt/sources.list.d/*.list
	  sed -i 's#/updates#-updates#g' /etc/apt/sources.list.d/*.list
  fi
  __do_apt_upgrade
  }

__do_release_upgrade
```

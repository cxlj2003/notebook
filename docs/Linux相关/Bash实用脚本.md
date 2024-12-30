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
rm -rf /etc/apt/sources.list.d/*.sources
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

```
cat << EOF > /etc/modules-load.d/bonding.conf
bonding
EOF
modprobe bonding
lsmod | grep bonding

rm -rf /etc/netplan/*
ip4=113
bond1_active=ens32
bond1_backup=ens34
bond1_addr="198.51.100.${ip4}/24"
bond1_gw='198.51.100.254'
bond2_active=ens35
bond2_backup=ens36
bond2_addr="198.19.32.${ip4}/24"
bond3_active=ens37
bond3_backup=ens38
bond4_active=ens39
bond4_backup=ens40
bond4_addr="198.19.33.${ip4}/24"
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

服务器:
```
ntpserver1='time.windows.com'
ntpserver2='pool.ntp.org'
get_os_type() {
if [ ! -e /etc/os-release ];then
  echo 'Unable get linux distribution !'
fi
source /etc/os-release
echo $ID
}
case $(get_os_type) in
	anolis|kylin|openEuler )
		yum install chrony -y
		sed -i  '/^pool.*iburst/d' /etc/chrony.conf
		cat << EOF >> /etc/chrony.conf
pool $ntpserver1 iburst
pool $ntpserver2 iburst
allow 0.0.0.0/0	
EOF
        systemctl enable --now chronyd
        systemctl restart chronyd
		;;
	debian|ubuntu )
		apt update
		export DEBIAN_FRONTEND=noninteractive
		apt install chrony -y
		sed -i  '/^pool.*iburst/d' /etc/chrony/chrony.conf
		cat << EOF >> /etc/chrony/chrony.conf
pool $ntpserver1 iburst
pool $ntpserver2 iburst
allow 0.0.0.0/0		
EOF
        systemctl restart chrony
		;;
esac
chronyc sources
```

客户端:
```
ntpserver1='192.168.0.1'
ntpserver2='192.168.0.2'
get_os_type() {
if [ ! -e /etc/os-release ];then
  echo 'Unable get linux distribution !'
fi
source /etc/os-release
echo $ID
}
case $(get_os_type) in
	anolis|kylin|openEuler )
		yum install chrony -y
		sed -i  '/^pool.*iburst/d' /etc/chrony.conf
		cat << EOF >> /etc/chrony.conf
pool $ntpserver1 iburst
pool $ntpserver2 iburst
EOF
        systemctl enable --now chronyd
        systemctl restart chronyd
		;;
	debian|ubuntu )
		apt update
		export DEBIAN_FRONTEND=noninteractive
		apt install chrony -y
		sed -i  '/^pool.*iburst/d' /etc/chrony/chrony.conf
		cat << EOF >> /etc/chrony/chrony.conf
pool $ntpserver1 iburst
pool $ntpserver2 iburst
EOF
        systemctl enable --now chrony
        systemctl restart chrony
		;;
esac
```

# 5. 远程运行脚本

```
HOSTS='
198.19.201.130
'
for HOST in ${HOSTS};do
	 ssh root@${HOST} cat <<'EEOOFF' > /tmp/r.sh
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt -y install chrony
systemctl enable --now chronyd
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
EEOOFF
 ssh root@${HOST} 'bash ' /tmp/r.sh
done

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

用于oldrelease升级至release
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

>[!IMPORTANT]
>升级不可跨越版本

# 8.`reposync/apt-mirror`创建镜像源

## 8.1 kylinv10 yum

```
#!/bin/bash
kylinv10_repos(){
cat << EOF > /etc/yum.repos.d/kylinv10.repo
###Kylin Linux Advanced Server 10 SP1 x86_64 - os repo###

[kylin_V10_SP1_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP1 x86_64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/base/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP1_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP1 x86_64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/updates/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP1_x86_64-adv-addons]
name = Kylin Linux Advanced Server 10 SP1 x86_64 - Addons
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/addons/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0

###Kylin Linux Advanced Server 10 SP2 x86_64 - os repo###

[kylin_V10_SP2_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP2 x86_64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/base/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP2_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP2 x86_64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/updates/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP2_x86_64-adv-addons]
name = Kylin Linux Advanced Server 10 SP2 x86_64 - Addons
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/addons/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0

###Kylin Linux Advanced Server 10 SP3 x86_64  - os repo###

[kylin_V10_SP3_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP3 x86_64 - Os 
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/base/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP3_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP3 x86_64 - Updates
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/updates/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP3_x86_64-adv-addons]
name = Kylin Linux Advanced Server 10 SP3 x86_64 - Addons
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/addons/x86_64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0

##########################################################
###Kylin Linux Advanced Server 10 SP1 aarch64 - os repo###

[kylin_V10_SP1_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP1 aarch64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/base/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP1_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP1 aarch64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/updates/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP1_aarch64-adv-addons]
name = Kylin Linux Advanced Server 10 SP1 aarch64 - Addons
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/addons/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0

###Kylin Linux Advanced Server 10 SP2 aarch64 - os repo###

[kylin_V10_SP2_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP2 aarch64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/base/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP2_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP2 aarch64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/updates/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP2_aarch64-adv-addons]
name = Kylin Linux Advanced Server 10 SP2 aarch64 - Addons
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/addons/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0

###Kylin Linux Advanced Server 10 SP3 aarch64 - os repo###

[kylin_V10_SP3_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP3 aarch64 - Os 
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/base/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP3_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP3 aarch64 - Updates
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/updates/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[kylin_V10_SP3_aarch64-adv-addons]
name = Kylin Linux Advanced Server 10 SP3 aarch64 - Addons
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/addons/aarch64/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
}

init_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`

for repo in ${repo_list};do 
  if [ ! -d ${repo_root}/${repo} ];then
    mkdir -p ${repo_root}/${repo}/Packages/
  fi
  reposync --urls --repoid ${repo} > ${repo_root}/${repo}/${repo}.txt
  file=${repo_root}/${repo}/${repo}.txt
  cat $file | while read line;do
    echo $line
    axel -k -c -p -n 4 $line -o ${repo_root}/${repo}/Packages/
  done
done

for repo in ${repo_list};do
   reposync --repoid ${repo} -p ${repo_root}
done 
}

init_downloader kylin

update_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`
for repo in ${repo_list};do
  reposync --repoid ${repo} -np  ${repo_root}/
  createrepo --repo ${repo} --update  ${repo_root}/${repo}
done
}
update_downloader kylin

zwc_yum_server(){
yum_server_list='
100.201.3.111
100.0.0.239
192.168.10.239
'
for yum_server in ${yum_server_list};do
 if curl --connect-timeout 2 ${yum_server} &> /dev/null ;then
   echo ${yum_server}
   break
 else
   continue
 fi
done
}

kylinv10_local_repos(){
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/yum.repos.d
local http_scheme='http://'
local http_port=':80'
yum_server_list='
100.201.3.111
100.0.0.239
192.168.10.239
'
for zwc_yum_server in ${yum_server_list};do
local local_server=${zwc_yum_server}
local repourl=${http_scheme}${local_server}${http_port}/zwc-kylin
local version_arch='
kylin_V10_SP1_aarch64
kylin_V10_SP2_aarch64
kylin_V10_SP3_aarch64
kylin_V10_SP1_x86_64
kylin_V10_SP2_x86_64
kylin_V10_SP3_x86_64
'

#[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os]
#[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates]
  for v_a in ${version_arch};do
cat << EOF > ${repo_root}/${zwc_yum_server}_${v_a}.repo
##zwc-${v_a}##
[zwc-${v_a}-adv-os]
name = zwc ${v_a} adv-os
baseurl = ${repourl}/${v_a}-adv-os
enabled = 1
[zwc-${v_a}-adv-updates]
name = zwc ${v_a} adv-updates
baseurl = ${repourl}/${v_a}-adv-updates
enabled = 1
EOF
  done
done
}
kylinv10_local_repos

main(){
kylinv10_repos
init_downloader
update_downloader
}
```

## 8.2 InLinux yum

```
#!/bin/bash
cat << EOF > /etc/yum.repos.d/inlinux.repo
[inlinux_23.12_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/aarch64/
gpgcheck = 0
enabled = 1

[inlinux_23.12_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/x86_64/
gpgcheck = 0
enabled = 1

[inlinux_23.12_sp1_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_sp1_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/aarch64/
gpgcheck = 0
enabled = 1

[inlinux_23.12_sp1_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_sp1_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/x86_64/
gpgcheck = 0
enabled = 1
EOF

init_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`

for repo in ${repo_list};do 
  if [ ! -d ${repo_root}/${repo} ];then
    mkdir -p ${repo_root}/${repo}/Packages/
  fi
  reposync --urls --repoid ${repo} > ${repo_root}/${repo}/${repo}.txt
  file=${repo_root}/${repo}/${repo}.txt
  cat $file | while read line;do
    echo $line
    axel -k -c -p -n 4 $line -o ${repo_root}/${repo}/Packages/
  done
done

for repo in ${repo_list};do
   reposync --repoid ${repo} -p ${repo_root}
done 
}

init_downloader inlinux


update_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`
for repo in ${repo_list};do
  reposync --repoid ${repo} -np  ${repo_root}/
  createrepo --repo ${repo} --update  ${repo_root}/${repo}
done
}
update_downloader inlinux

inlinux_local_repos(){
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/yum.repos.d
local http_scheme='http://'
local http_port=':80'
yum_server_list='
100.201.3.111
100.0.0.239
192.168.10.239
'
for zwc_yum_server in ${yum_server_list};do
local local_server=${zwc_yum_server}
local repourl=${http_scheme}${local_server}${http_port}/zwc-inlinux
local version_arch='
inlinux_23.12_aarch64
inlinux_23.12_x86_64
inlinux_23.12_SP1_aarch64
inlinux_23.12_SP1_x86_64
'

#[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os]
#[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates]
  for v_a in ${version_arch};do
cat << EOF > ${repo_root}/${zwc_yum_server}_${v_a}.repo
##zwc-${v_a}##
[zwc-${v_a}-everything]
name = zwc ${v_a} everything
baseurl = ${repourl}/${v_a}-everything
enabled = 1
[zwc-${v_a}-update]
name = zwc ${v_a} update
baseurl = ${repourl}/${v_a}-update
enabled = 1
EOF
  done
done
}
inlinux_local_repos


```

## 8.3 Ubuntu apt

```

```

## 8.4 通用docker
### 8.4.1宿主机

```
/opt/.docker_root
/opt/www/html
/opt/mirrors/
zwc-kylin/NS/V10/V10SP3/os/adv/lic/{base,updates}/{aarch64,x86_64}
zwc-inlinux/InLinux-23.12-LTS-SP1/{everything,update}/{aarch64,x86_64}
```
### 8.4.2`Docker`
```
yum -y install dnf-plugins-core createrepo
mkdir -p /repo/{aarch64,x86_64}
reposync -p /repos/aarch64  --forcearch aarch64
reposync -p /repo/x86_64  --forcearch x86_64

```

### 8.4.3 `Docker`镜像

#### `Dockerfile`
```dockerfile
FROM registry.cn-hangzhou.aliyuncs.com/cxlj/openeuler:24.03-lts
ENV TZ=Asia/Shanghai
RUN yum -y update && \
yum -y install dnf-plugins-core createrepo cronie && \
rm -rf /etc/yum.repos.d/* && \
yum clean all && rm -rf /var/cache/dnf/*

COPY local.repo /etc/yum.repos.d/local.repo
COPY start.sh /start.sh

VOLUME [ "/opt/mirrors" ]
ENTRYPOINT [ "/start.sh"  ]
```
#### `local.repo`
```
##############################x86_64##############################

###Kylin Linux Advanced Server 10 SP1 x86_64 repo###

[kylin_V10_SP1_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP1 x86_64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/base/x86_64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP1_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP1 x86_64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/updates/x86_64/
gpgcheck = 0
enabled = 1

###Kylin Linux Advanced Server 10 SP2 x86_64 repo###

[kylin_V10_SP2_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP2 x86_64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/base/x86_64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP2_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP2 x86_64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/updates/x86_64/
gpgcheck = 0
enabled = 1

###Kylin Linux Advanced Server 10 SP3 x86_64 repo###

[kylin_V10_SP3_x86_64-adv-os]
name = Kylin Linux Advanced Server 10 SP3 x86_64 - Os 
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/base/x86_64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP3_x86_64-adv-updates]
name = Kylin Linux Advanced Server 10 SP3 x86_64 - Updates
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/updates/x86_64/
gpgcheck = 0
enabled = 1

###InLinux 23.12 x86_64  repo###

[inlinux_23.12_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/x86_64/
gpgcheck = 0
enabled = 1

###InLinux 23.12 SP1 x86_64  repo###

[inlinux_23.12_sp1_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_sp1_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/x86_64/
gpgcheck = 0
enabled = 1

##############################aarch64##############################

###Kylin Linux Advanced Server 10 SP1 aarch64 repo###

[kylin_V10_SP1_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP1 aarch64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/base/aarch64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP1_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP1 aarch64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP1/os/adv/lic/updates/aarch64/
gpgcheck = 0
enabled = 1

###Kylin Linux Advanced Server 10 SP2 aarch64 repo###

[kylin_V10_SP2_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP2 aarch64 - Os 
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/base/aarch64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP2_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP2 aarch64 - Updates
baseurl = http://update.cs2c.com.cn:8080/NS/V10/V10SP2/os/adv/lic/updates/aarch64/
gpgcheck = 0
enabled = 1

###Kylin Linux Advanced Server 10 SP3 aarch64 repo###

[kylin_V10_SP3_aarch64-adv-os]
name = Kylin Linux Advanced Server 10 SP3 aarch64 - Os 
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/base/aarch64/
gpgcheck = 0
enabled = 1
[kylin_V10_SP3_aarch64-adv-updates]
name = Kylin Linux Advanced Server 10 SP3 aarch64 - Updates
baseurl = https://update.cs2c.com.cn/NS/V10/V10SP3/os/adv/lic/updates/aarch64/
gpgcheck = 0
enabled = 1

###InLinux 23.12  aarch64  repo###

[inlinux_23.12_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/aarch64/
gpgcheck = 0
enabled = 1

###InLinux 23.12 SP1 aarch64  repo###

[inlinux_23.12_sp1_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux_23.12_sp1_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/aarch64/
gpgcheck = 0
enabled = 1
```

#### `start.sh`
```
#!/bin/bash
cat << 'EOF' > /root/init_mirrors.sh
#!/bin/bash
set -ex
init_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`

for repo in ${repo_list};do 
  if [ ! -d ${repo_root}/${repo} ];then
    mkdir -p ${repo_root}/${repo}/Packages/
  fi
  for repo in ${repo_list};do
   reposync --repoid ${repo} -p ${repo_root}
  done
done 
}
init_downloader kylin &> /dev/null &
init_downloader inlinux &> /dev/null &
EOF

cat << 'EOF' > /root/update_mirrors.sh
#!/bin/bash
set -ex
update_downloader(){
local reponame=$1
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/${reponame}
local repo_list=`yum repolist |grep -E ${reponame}  |awk  '{print $1}' |xargs`
for repo in ${repo_list};do
  reposync --repoid ${repo} -np  ${repo_root}/
  createrepo --repo ${repo} --update  ${repo_root}/${repo}
done
}
update_downloader kylin &> /dev/null &
update_downloader inlinux  &> /dev/null &
set +ex
EOF

cat << EOF > /var/spool/cron/root
0 0 * * * /usr/bin/bash /root/update_mirrors.sh &> /dev/null &
EOF

set +ex
tail -f /dev/null
```

使用`docker bulid -t local_mirrors:v1.1 .`命令创建镜像
#### `docker-compose.yaml`
```yaml
version: '3.3'
services:
  app:
    image: local_mirrors:v1.1
    container_name: local_mirrors
    hostname: local_mirrors
    volumes:
      - /opt/mirrors:/opt/mirrors
    privileged: true
    environment:
      - "UID:0"
      - "GID:0"
      - "GIDLIST:0"
    restart: always
```

使用`docker compose up -d`命令启动,使用`docker exec -it local_mirrors bash`进入docker内部,使用`bash /root/init_mirrors.sh`命令启动初始化脚本.

# 9.创建docker镜像

## 9.1创建Dockerflie
```Dockerfile
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
FROM registry.cn-hangzhou.aliyuncs.com/cxlj/openeuler:22.03-lts as bootstrap

ARG TARGETARCH

ARG SP_VERSION

RUN echo "I'm building inlinux-23.12-sp${SP_VERSION} for arch ${TARGETARCH}"
RUN rm -rf /target && mkdir -p /target/etc/yum.repos.d && mkdir -p /etc/pki/rpm-gpg
COPY inlinux-23.12-lts-sp1.repo /target/etc/yum.repos.d/inlinux.repo
COPY RPM-GPG-KEY-InLinux /target/etc/pki/rpm-gpg/RPM-GPG-KEY-InLinux
COPY RPM-GPG-KEY-InLinux /etc/pki/rpm-gpg/RPM-GPG-KEY-InLinux

# see https://github.com/BretFisher/multi-platform-docker-build
# make the yum repo file with correct filename; eg: inlinux_x86_64.repo
RUN case ${TARGETARCH} in \
         "amd64")  ARCHNAME=x86_64  ;; \
         "arm64")  ARCHNAME=aarch64  ;; \
    esac && \
    mv /target/etc/yum.repos.d/inlinux.repo /target/etc/yum.repos.d/inlinux_${ARCHNAME}.repo

RUN yum --installroot=/target \
    --releasever=23.12LTS_SP1 \
    --setopt=tsflags=nodocs \
    install -y InLinux-release coreutils rpm yum bash procps tar

FROM scratch as runner
COPY --from=bootstrap /target /
RUN yum --releasever=23.12LTS_SP1 \
    --setopt=tsflags=nodocs \
    install -y InLinux-release coreutils rpm yum bash procps tar
RUN yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /var/log/*
RUN  echo export LANG='en_US.UTF-8' >> /etc/profile && \
     echo export LC_ALL='en_US.UTF-8' >> /etc/profile && \
     ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

FROM scratch
COPY --from=runner / /
CMD /bin/bash
```
[文件](https://github.com/cxlj2003/demo/tree/main/inlinux/23.12-sp1)
>[!NOTE]
>1.`$releaserver` 取值为release文件中的version;
>命令: `rpm -qi $(rpm -qa |grep -Ev 'latest' |grep -E 'release')|awk -F : '/Version/{print $2}' |sed -n 's/ //p'`
>2.`$basearch` 取值 `arch`


## 9.2镜像生成脚本
```
SP_VERSION=1 && docker buildx build --progress=plain --no-cache . -f Dockerfile --platform=linux/amd64 -t inlinux:23.12-sp$SP_VERSION-amd64 --build-arg SP_VERSION=$SP_VERSION 2>&1 | tee inlinux:23.12-sp$SP_VERSION-amd64-build.log
SP_VERSION=1 && docker buildx build --progress=plain --no-cache . -f Dockerfile --platform=linux/arm64 -t inlinux:23.12-sp$SP_VERSION-arm64 --build-arg SP_VERSION=$SP_VERSION 2>&1 | tee inlinux:23.12-sp$SP_VERSION-arm64-build.log
```

# 10.文件
## 10.1挂载cifs

使用命令行挂载
```
mount -t cifs -o \
username=<user>,password=<password> \
//WIN_SHARE_IP/<share_name> /mnt/win_share
```
使用
```
cat << 'EOF' > /etc/win-credentials
username = user
password = password
domain = domain
EOF
mount -t cifs -o credentials=/etc/win-credentials //WIN_SHARE_IP/<share_name> /mnt/win_share
```

```
cat << 'EOF' > /etc/win-credentials
username = user
password = password
domain = domain
EOF
cat << 'EOF' >> /etc/fstab
//WIN_SHARE_IP/share_name  /mnt/win_share  cifs  credentials=/etc/win-credentials,file_mode=0755,dir_mode=0755 0       0
EOF
mount -a
```

## 10.2 `rsync`

yum源同步脚本
### 10.2.1 centos7-vault
```
#!/bin/bash
cat << 'EOF' > /opt/mirrors/include_vault1
+ 7*
+ 7*/
+ 7*/**
- *
EOF

cat << 'EOF' > /opt/mirrors/include_vault2
+ centos/
+ centos/7*
+ centos/7*/
+ centos/7*/**
- *
EOF

cat << 'EOF' > /opt/mirrors/include_vault3
+ altarch/
+ altarch/7*
+ altarch/7*/
+ altarch/7*/**
- *
EOF

/usr/bin/rsync -arztvP rsync://mirrors.tuna.tsinghua.edu.cn/centos-vault/ /opt/mirrors/centos-vault/ --include-from=/opt/mirrors/include_vault1
/usr/bin/rsync -arztvP rsync://mirrors.tuna.tsinghua.edu.cn/centos-vault/ /opt/mirrors/centos-vault/ --include-from=/opt/mirrors/include_vault2
/usr/bin/rsync -arztvP rsync://mirrors.tuna.tsinghua.edu.cn/centos-vault/ /opt/mirrors/centos-vault/ --include-from=/opt/mirrors/include_vault3
```

### 10.2.2 epel7-vault
```
#!/bin/bash
cat << 'EOF' > /opt/mirrors/include_epel1
+ aarch64/
+ aarch64/**
- *
EOF

cat << 'EOF' > /opt/mirrors/include_epel2
+ x86_64/
+ x86_64/**
- *
EOF

cat << 'EOF' > /opt/mirrors/include_epel3
+ source/
+ source/**
- *
EOF

/usr/bin/rsync -arztvP rsync://ftp-stud.hs-esslingen.de/fedora-archive/epel/7/ /opt/mirrors/epel/7/ --include-from=/opt/mirrors/include_epel1
/usr/bin/rsync -arztvP rsync://ftp-stud.hs-esslingen.de/fedora-archive/epel/7/ /opt/mirrors/epel/7/ --include-from=/opt/mirrors/include_epel2
/usr/bin/rsync -arztvP rsync://ftp-stud.hs-esslingen.de/fedora-archive/epel/7/ /opt/mirrors/epel/7/ --include-from=/opt/mirrors/include_epel3
```

# 11. `Docker-CE`

## 11.1 ubuntu


```
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

```

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove $pkg -y; done

apt-get update
apt-get install ca-certificates curl gnupg -y

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

# 12. kolla-ansilbe docker 镜像

```
#!/bin/bash
set -ex
public_registry=docker.io
image_namespace=kolla
private_registry=registry.cn-hangzhou.aliyuncs.com
private_namespace=mgt
openstack_release=2024.1
image_base_os=ubuntu-jammy
image_list=`kolla-build -b ubuntu --openstack-release ${openstack_release} --list-images |awk  '{print $NF}'`
for image in $image_list;do
        docker pull $public_registry/$image_namespace/$image:$openstack_release-$image_base_os
        docker tag $public_registry/$image_namespace/$image:$openstack_release-$image_base_os $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
        docker push $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
        docker rmi  $public_registry/$image_namespace/$image:$openstack_release-$image_base_os
        docker rmi $private_registry/$private_namespace/$image:$openstack_release-$image_base_os
done

set +ex
```
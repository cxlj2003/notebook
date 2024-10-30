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
		sed -i  '/pool/d' /etc/chrony.conf
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
		sed -i  '/pool/d' /etc/chrony/chrony.conf
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

# 8.`reposync`创建yum镜像源

## 8.1 kylinv10

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
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/kylin
local repo_list=`yum repolist |awk '/kylin/{print $1}' |xargs`

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

update_downloader(){
local mirrors_root=/opt/mirrors
local repo_root=${mirrors_root}/kylin
local repo_list=`yum repolist |awk '/kylin/{print $1}' |xargs`
for repo in ${repo_list};do
  reposync --repoid ${repo} -np  ${repo_root}/
  #reposync --repoid ks10sp2_aarch64-adv-os -np /opt/mirrors/kylin
  createrepo --repo ${repo} --update  ${repo_root}/${repo}
  # createrepo --repo ks10sp2_aarch64-adv-os --update /opt/mirrors/kylin/ks10sp2_aarch64-adv-os
done
}

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
local local_server=$(zwc_yum_server)
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
cat << EOF > ${repo_root}/kylin_${v_a}.repo
##zwc-${v_a}##
[zwc-${v_a}-adv-os]
name = zwc KylinV10 adv-os
baseurl = ${repourl}/${v_a}-adv-os
enabled = 1
[zwc-${v_a}-adv-updates]
name = zwc KylinV10 adv-updates
baseurl = ${repourl}/${v_a}-adv-updates
enabled = 1
EOF
done
}
kylinv10_local_repos

main(){
kylinv10_repos
init_downloader
update_downloader
}
```

## 8.2 InLinux

```
#!/bin/bash
cat << EOF > /etc/yum.repos.d/inlinux.repo
[inlinux23_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux23_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/aarch64/
gpgcheck = 0
enabled = 1

[inlinux23_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux23_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS/update/x86_64/
gpgcheck = 0
enabled = 1

[inlinux23sp1_aarch64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/aarch64/
gpgcheck = 0
enabled = 1
[inlinux23sp1_aarch64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/aarch64/
gpgcheck = 0
enabled = 1

[inlinux23sp1_x86_64_everything]
name = InLinux-23.12-LTS everything
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/everything/x86_64/
gpgcheck = 0
enabled = 1
[inlinux23sp1_x86_64_update]
name = InLinux-23.12-LTS update
baseurl = https://repos-inlinux.inspurcloud.cn/InLinux-23.12-LTS-SP1/update/x86_64/
gpgcheck = 0
enabled = 1
EOF

for repo in `yum repolist |awk '/inlinux/{print $1}' |xargs`;do 
  if [ ! -d /opt/mirrors/inlinux/${repo} ];then
    mkdir -p /opt/mirrors/inlinux/${repo}/Packages/
  fi
  reposync --urls --repoid ${repo} > /opt/mirrors/inlinux/${repo}/${repo}.txt
  file=/opt/mirrors/inlinux/${repo}/${repo}.txt
  cat $file | while read line;do
    echo $line
    axel -k -c -p -n 4 $line -o /opt/mirrors/inlinux/${repo}/Packages/
  done
done

for repo in `yum repolist |awk '/inlinux/{print $1}' |xargs`;do
   reposync --repoid ${repo} -p /opt/mirrors/inlinux
done 


for repo in `yum repolist |awk '/inlinux/{print $1}' |xargs`;do
  reposync -g -m -np /opt/mirrors/inlinux/${repo}
  createrepo --update /opt/mirrors/inlinux/${repo}
done
```
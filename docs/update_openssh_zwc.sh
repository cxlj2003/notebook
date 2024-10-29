#!/bin/bash
set -ex
zlib_release='zlib-1.3.1'
openssl_release='openssl-3.3.2'
openssh_release='openssh-9.9p1'

yum_server_list='
100.201.3.111
100.0.0.239
192.168.10.239
'

if [ ! -e /etc/os-release ];then
 echo 'Cannot detect Linux distribution! Aborting.'
 exit 1
else
 source /etc/os-release
fi

use_custom_mirrors(){
local yum_server=$1
local os_type=${ID}
local os_version_id=${VERSION_ID}

if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 for repo in `ls /etc/yum.repos.d/ | egrep 'repo$'`;do 
  alias mv='mv' 
  mv -f /etc/yum.repos.d/${repo} /etc/yum.repos.d/${repo}.bak
 done
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
 for list in `ls /etc/apt/ |egrep 'list$'`;do
 	alias mv='mv'
 	mv -f /etc/apt/${list} /etc/apt/${list}.bak
 done
 for source in `ls /etc/apt/sources.list.d/ |egrep 'sources$'`;do
 	alias mv='mv'
 	mv -f /etc/apt/sources.list.d/${source} /etc/apt/sources.list.d/${source}.bak 	
 done
fi
if [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 7 ]];then 
 cat << EOF > /etc/yum.repos.d/AnolisOS-os.repo
[os]
name=AnolisOS-\$releasever - os
baseurl=http://${yum_server}/anolis/\$releasever/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-extras.repo
[extras]
name=AnolisOS-\$releasever - extras
baseurl=http://${yum_server}/anolis/\$releasever/extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-updates.repo
[updates]
name=AnolisOS-\$releasever - updates
baseurl=http://${yum_server}/anolis/\$releasever/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 8 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS-AppStream.repo
[AppStream]
name=AnolisOS-\$releasever - AppStream
baseurl=http://${yum_server}/anolis/\$releasever/AppStream/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-BaseOS.repo
[BaseOS]
name=AnolisOS-\$releasever - BaseOS
baseurl=http://${yum_server}/anolis/\$releasever/BaseOS/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-Extras.repo
[Extras]
name=AnolisOS-\$releasever - Extras
baseurl=http://${yum_server}/anolis/\$releasever/Extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-PowerTools.repo
[PowerTools]
name=AnolisOS-\$releasever - PowerTools
baseurl=http://${yum_server}/anolis/\$releasever/PowerTools/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-kernel-5.10.repo
[kernel-5.10]
name=AnolisOS-\$releasever - Kernel 5.10
baseurl=http://${yum_server}/anolis/\$releasever/kernel-5.10/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 23 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS.repo 
[os]
name=AnolisOS-\$releasever - os
baseurl=http://${yum_server}/anolis/\$releasever/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[updates]
name=AnolisOS-\$releasever - updates
baseurl=http://${yum_server}/anolis/\$releasever/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[kernel-6]
name=AnolisOS-\$releasever - kernel-6
baseurl=http://${yum_server}/anolis/\$releasever/kernel-6/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'kylin' ]];then
local sub_version=`cat /etc/.kyinfo|grep dist_id |sed -e 's/-Release.*//' -e 's/^dist_id.*SP/SP/'`
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server ${os_version_id} - Os 
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/base/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server ${os_version_id} - Updates
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/updates/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server ${os_version_id} - Addons
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/addons/\$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
elif [[ ${os_type} == 'openEuler' ]];then
local sub_version=`cat /etc/os-release |awk -F \" '/VERSION=/{print $(NF-1)}' |sed -e 's/(//g' -e 's/)//g' -e 's/ /-/g'`
cat << EOF > /etc/yum.repos.d/openEuler.repo
[OS]
name=OS
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/OS'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[everything]
name=everything
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/everything/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/everything'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/everything/\$basearch/RPM-GPG-KEY-openEuler

[EPOL]
name=EPOL
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/EPOL/main/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/EPOL/main'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[debuginfo]
name=debuginfo
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/debuginfo/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/debuginfo'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/debuginfo/\$basearch/RPM-GPG-KEY-openEuler

[source]
name=source
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever'&'arch=source
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/RPM-GPG-KEY-openEuler

[update]
name=update
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/update/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/update'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[update-source]
name=update-source
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/update/source/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/update'&'arch=source
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/RPM-GPG-KEY-openEuler
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'buster' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ buster main contrib non-free
deb-src http://${yum_server}/debian/ buster main contrib non-free

deb http://${yum_server}/debian/ buster-updates main contrib non-free
deb-src http://${yum_server}/debian/ buster-updates main contrib non-free

deb http://${yum_server}/debian/ buster-backports main contrib non-free
deb-src http://${yum_server}/debian/ buster-backports main contrib non-free

deb http://${yum_server}/debian-security/ buster/updates main contrib non-free
deb-src http://${yum_server}/debian-security/ buster/updates main contrib non-free
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'bullseye' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ bullseye main contrib non-free
deb-src http://${yum_server}/debian/ bullseye main contrib non-free

deb http://${yum_server}/debian/ bullseye-updates main contrib non-free
deb-src http://${yum_server}/debian/ bullseye-updates main contrib non-free

deb http://${yum_server}/debian/ bullseye-backports main contrib non-free
deb-src http://${yum_server}/debian/ bullseye-backports main contrib non-free

deb http://${yum_server}/debian-security/ bullseye-security main contrib non-free
deb-src http://${yum_server}/debian-security/ bullseye-security main contrib non-free
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'bookworm' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm main contrib non-free non-free-firmware

deb http://${yum_server}/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm-updates main contrib non-free non-free-firmware

deb http://${yum_server}/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm-backports main contrib non-free non-free-firmware

deb http://${yum_server}/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
elif [[ ${os_type} == 'ubuntu' ]];then
: '
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse

## Not recommended
# deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
# deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
EOF
'
cat << EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://${yum_server}/ubuntu
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates ${VERSION_CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://${yum_server}/ubuntu
Suites: ${VERSION_CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
fi
if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 yum clean all 
 yum makecache
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
fi

}

env_installer(){
local os_type=${ID}
local os_version_id=${VERSION_ID}
if [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 7 ]];then
 echo 'anolis7.x'
 yum -y install vim wget tar nano gcc make pam-devel perl perl-CPAN perl-IPC-Cmd 
 echo yes | cpan -i List::Util
elif [[ ${os_type} == 'anolis' ]];then
 echo 'anolis>7.x'
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
elif [[ ${os_type} == 'kylin' ]];then
 echo kylin
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd
elif [[ ${os_type} == 'openEuler' ]];then
 echo openEuler
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
elif [[ ${os_type} == 'debian' ]];then
 echo debian
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
 apt -y install vim wget tar nano gcc make libpam0g-dev
elif [[ ${os_type} == 'ubuntu' ]];then
 echo ubuntu
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
 apt -y install vim wget tar nano gcc make libpam0g-dev
fi
}

file_download(){
local file_server=$1
local zlib_url=http://${file_server}/soft
local openssl_url=http://${file_server}/soft
local openssh_url=http://${file_server}/soft
local workdir=/usr/local/src
local zlib_release=$2
local openssl_release=$3
local openssh_release=$4
wget -nc -P ${workdir} ${zlib_url}/${zlib_release}.tar.gz 
wget -nc -P ${workdir} ${openssl_url}/${openssl_release}.tar.gz
wget -nc -P ${workdir} ${openssh_url}/${openssh_release}.tar.gz
}

zlib_installer(){
local zlib_release=$1
tar -zxvf /usr/local/src/${zlib_release}.tar.gz -C /usr/local/src/tar -zxvf /usr/local/src/${zlib_release}.tar.gz -C /usr/local/src/
cd /usr/local/src/${zlib_release}
./configure --prefix=/usr/local/zlib
make -j 4 && make test && make install
cat <<EOF > /etc/ld.so.conf.d/zlib.conf
/usr/local/zlib/lib
EOF
ldconfig
}

ssl_installer(){
local os_type=${ID}
local openssl_release=$1
tar -zxvf /usr/local/src/${openssl_release}.tar.gz -C /usr/local/src/
cd /usr/local/src/${openssl_release}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
make -j 8 && make install
if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 alias mv='mv'
 if [ -e /usr/bin/openssl ];then
  mv -f /usr/bin/openssl /usr/bin/oldopenssl
  ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
 fi
 if [ -e /usr/lib64/libssl.so.3 ];then
  rm -rf /usr/lib64/libssl.so.3*  
 fi
 ln -s /usr/local/openssl/lib64/libssl.so.3 /usr/lib64/libssl.so.3
 if [ -e /usr/lib64/libcrypto.so.3 ];then
  rm -rf /usr/lib64/libcrypto.so.3*  
 fi
 ln -s /usr/local/openssl/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
 alias mv='mv'
 if [ -e /usr/bin/openssl ];then
  mv -f /usr/bin/openssl /usr/bin/oldopenssl
  ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
 fi
 if [ -e /lib/x86_64-linux-gnu/libssl.so.3 ];then
  rm -rf /lib/x86_64-linux-gnu/libssl.so.3*  
 fi
 ln -s /usr/local/openssl/lib64/libssl.so.3 /lib/x86_64-linux-gnu/libssl.so.3
 if [ -e /lib/x86_64-linux-gnu/libcrypto.so.3 ];then
  rm -rf /lib/x86_64-linux-gnu/libcrypto.so.3*  
 fi
 ln -s /usr/local/openssl/lib64/libcrypto.so.3 /lib/x86_64-linux-gnu/libcrypto.so.3
fi
cat <<EOF > /etc/ld.so.conf.d/openssl_lib.conf
/usr/local/openssl/lib64
EOF
ldconfig
}

ssh_installer(){
local os_type=${ID}
local openssh_release=$1
tar -zxvf /usr/local/src/${openssh_release}.tar.gz -C /usr/local/src/
if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 yum -y remove openssh openssh-clients openssh-server 
 rm -rf /etc/ssh/*
 cd /usr/local/src/${openssh_release}
./configure --prefix=/usr \
--sysconfdir=/etc/ssh \
--with-pam \
--with-ssl-dir=/usr/local/openssl \
--with-zlib=/usr/local/zlib
make -j 4 && make install
rm -f /etc/init.d/sshd
alias cp='cp'
cp -rf /usr/local/src/${openssh_release}/contrib/redhat/sshd.init /etc/init.d/sshd
cp -rf /usr/local/src/${openssh_release}/contrib/redhat/sshd.pam /etc/pam.d/sshd
chkconfig --add sshd
chkconfig sshd on
systemctl daemon-reload
systemctl start sshd
chmod 600 /etc/ssh/*_key
cat << EOF >>/etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
EOF
systemctl restart sshd
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
apt -y remove ssh openssh-client openssh-server 
rm -rf /etc/ssh/*
openssh_release=openssh-9.9p1
cd /usr/local/src/${openssh_release}
./configure --prefix=/usr \
--sysconfdir=/etc/ssh \
--with-pam \
--with-ssl-dir=/usr/local/openssl \
--with-zlib=/usr/local/zlib
make -j 4 && make install
cat << EOF >> /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
EOF
chmod 600 /etc/ssh/*_key
chmod +x /etc/init.d/ssh
systemctl unmask ssh
systemctl start ssh
systemctl enable ssh 
fi
}

main(){
	local yum_server=$1
  local file_server=$2
  use_custom_mirrors ${yum_server}
  env_installer
  file_download  ${file_server} ${zlib_release} ${openssl_release} ${openssh_release}
  zlib_installer ${zlib_release}
  ssl_installer  ${openssl_release}
  ssh_installer  ${openssh_release}
  echo 'Update Complete!' 
}


for yum_server in ${yum_server_list};do
 if ! curl --connect-timeout 2 ${yum_server} &> /dev/null;then
   echo "${yum_server}不可达!"
   continue
 else
   main ${yum_server} ${yum_server}
 fi 
done

set +ex
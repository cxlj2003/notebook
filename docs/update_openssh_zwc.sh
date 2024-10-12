#!/bin/bash
ZLIB_RELEASE=zlib-1.3.1
OPENSSL_RELEASE=openssl-3.3.2
OPENSSH_RELEASE=openssh-9.9p1

if [ ! -e /etc/os-release ];then
 echo '*** Cannot detect Linux distribution! Aborting.'
 exit 1
else
 source /etc/os-release
fi

use_custom_mirrors() {
set -e
local SERVER_IP=$1
local ID=$2
local VERSION=$3
if [[ $ID == 'anolis' || $ID == 'kylin' || $ID == 'openEuler' ]];then
 for repo in `ls /etc/yum.repos.d/ | egrep 'repo$'`;do 
  alias mv='mv' 
  mv -f /etc/yum.repos.d/$repo /etc/yum.repos.d/$repo.bak
 done
elif [[ $ID == 'debian' ]];then
 echo '# Debian sources have moved to /etc/apt/sources.list.d/debian.sources' > /etc/apt/sources.list
elif [[ $ID == 'ubuntu' ]];then
 echo '# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources' > /etc/apt/sources.list
fi
if [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 7 ]];then 
 cat << EOF > /etc/yum.repos.d/AnolisOS-os.repo
[os]
name=AnolisOS-${VERSION} - os
baseurl=http://${SERVER_IP}/anolis/${VERSION}/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-extras.repo
[extras]
name=AnolisOS-${VERSION} - extras
baseurl=http://${SERVER_IP}/anolis/${VERSION}/extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-updates.repo
[updates]
name=AnolisOS-${VERSION} - updates
baseurl=http://${SERVER_IP}/anolis/${VERSION}/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 8 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS-AppStream.repo
[AppStream]
name=AnolisOS-\$releasever - AppStream
baseurl=http://${SERVER_IP}/anolis/\$releasever/AppStream/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-BaseOS.repo
[BaseOS]
name=AnolisOS-\$releasever - BaseOS
baseurl=http://${SERVER_IP}/anolis/\$releasever/BaseOS/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-Extras.repo
[Extras]
name=AnolisOS-\$releasever - Extras
baseurl=http://${SERVER_IP}/anolis/\$releasever/Extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-PowerTools.repo
[PowerTools]
name=AnolisOS-\$releasever - PowerTools
baseurl=http://${SERVER_IP}/anolis/\$releasever/PowerTools/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-kernel-5.10.repo
[kernel-5.10]
name=AnolisOS-\$releasever - Kernel 5.10
baseurl=http://${SERVER_IP}/anolis/\$releasever/kernel-5.10/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 23 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS.repo 
[os]
name=AnolisOS-\$releasever - os
baseurl=http://${SERVER_IP}/anolis/\$releasever/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[updates]
name=AnolisOS-\$releasever - updates
baseurl=http://${SERVER_IP}/anolis/\$releasever/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[kernel-6]
name=AnolisOS-\$releasever - kernel-6
baseurl=http://${SERVER_IP}/anolis/\$releasever/kernel-6/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ $ID == 'kylin' ]];then
local REVERSION=`cat /etc/.kyinfo|grep dist_id |sed -e 's/-Release.*//' -e 's/^dist_id.*SP/SP/'`
cat << EOF > /etc/yum.repos.d/KylinV10_${REVERSION}.repo
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server 10 - Os 
baseurl = http://${SERVER_IP}/${ID}/NS/V10/V10${REVERSION}/os/adv/lic/base/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server 10 - Updates
baseurl = http://${SERVER_IP}/${ID}/NS/V10/V10${REVERSION}/os/adv/lic/updates/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server 10 - Addons
baseurl = http://${SERVER_IP}/${ID}/NS/V10/V10${REVERSION}/os/adv/lic/addons/\$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
elif [[ $ID == 'openEuler' ]];then
local REVERSION=echo $VERSION|sed -e 's/(//g' -e 's/)//g' -e 's/ /-/g'
cat << EOF > /etc/yum.repos.d/openEuler.repo
[OS]
name=OS
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/OS/\$basearch/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/OS'&'arch=\$basearch
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/OS/\$basearch/RPM-GPG-KEY-openEuler

[everything]
name=everything
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/everything/\$basearch/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/everything'&'arch=\$basearch
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/everything/\$basearch/RPM-GPG-KEY-openEuler

[EPOL]
name=EPOL
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/EPOL/main/\$basearch/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/EPOL/main'&'arch=\$basearch
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/OS/\$basearch/RPM-GPG-KEY-openEuler

[debuginfo]
name=debuginfo
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/debuginfo/\$basearch/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/debuginfo'&'arch=\$basearch
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/debuginfo/\$basearch/RPM-GPG-KEY-openEuler

[source]
name=source
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/source/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever'&'arch=source
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/source/RPM-GPG-KEY-openEuler

[update]
name=update
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/update/\$basearch/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/update'&'arch=\$basearch
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/OS/\$basearch/RPM-GPG-KEY-openEuler

[update-source]
name=update-source
baseurl=http://${SERVER_IP}/openEuler-${REVERSION}/update/source/
metalink=http://${SERVER_IP}/metalink?repo=\$releasever/update'&'arch=source
metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${SERVER_IP}/openEuler-${REVERSION}/source/RPM-GPG-KEY-openEuler
EOF
elif [[ $ID == 'debian' ]];then
cat << EOF > /etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://${SERVER_IP}/debian
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://${SERVER_IP}/debian-security
Suites: ${VERSION_CODENAME}-security
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
elif [[ $ID == 'ubuntu' ]];then
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
fi
if [[ $ID == 'anolis' || $ID == 'kylin' || $ID == 'openEuler' ]];then
 yum clean all 
 yum makecache
elif [[ $ID == 'debian' || $ID == 'ubuntu' ]];then
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
fi
set +ex
}

env_installer() {
set -ex
local ID=$1
local VERSION=$2
if [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 7 ]];then
 echo 'anolis7.x'
 yum -y install vim wget tar nano gcc make pam-devel perl perl-CPAN perl-IPC-Cmd 
 echo yes | cpan -i List::Util
elif [[ $ID == 'anolis' ]];then
 echo 'anolis>7.x'
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
elif [[ $ID == 'kylin' ]];then
 echo kylin
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd
elif [[ $ID == 'openEuler' ]];then
 echo openEuler
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
elif [[ $ID == 'debian' ]];then
 echo debian
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
 apt -y install vim wget tar nano gcc make libpam0g-dev
elif [[ $ID == 'ubuntu' ]];then
 echo ubuntu
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
 apt -y install vim wget tar nano gcc make libpam0g-dev
fi
set +ex
}

file_download() {
local SERVER_IP=$1
local ZLIB_URL=http://${SERVER_IP}/soft
local OPENSSL_URL=http://${SERVER_IP}/soft
local OPENSSH_URL=http://${SERVER_IP}/soft
local WORKDIR=/usr/local/src
local ZLIB_RELEASE=$2
local OPENSSL_RELEASE=$3
local OPENSSH_RELEASE=$4
wget -nc -P ${WORKDIR} ${ZLIB_URL}/${ZLIB_RELEASE}.tar.gz 
wget -nc -P ${WORKDIR} ${OPENSSL_URL}/${OPENSSL_RELEASE}.tar.gz
wget -nc -P ${WORKDIR} ${OPENSSH_URL}/${OPENSSH_RELEASE}.tar.gz
}

zlib_installer() {
local ZLIB_RELEASE=$1
tar -zxvf /usr/local/src/${ZLIB_RELEASE}.tar.gz -C /usr/local/src/
cd /usr/local/src/${ZLIB_RELEASE}
./configure --prefix=/usr/local/zlib
make -j 4 && make test && make install
cat <<EOF > /etc/ld.so.conf.d/zlib.conf
/usr/local/zlib/lib
EOF
ldconfig
}

ssl_installer() {
local ID=$1
local OPENSSL_RELEASE=$2
tar -zxvf /usr/local/src/${OPENSSL_RELEASE}.tar.gz -C /usr/local/src/
cd /usr/local/src/${OPENSSL_RELEASE}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
make -j 8 && make install
if [[ $ID == 'anolis' || $ID == 'kylin' || $ID == 'openEuler' ]];then
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
elif [[ $ID == 'debian' || $ID == 'ubuntu' ]];then
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

ssh_installer() {
local ID=$1
local OPENSSH_RELEASE=$2
if [[ $ID == 'anolis' || $ID == 'kylin' || $ID == 'openEuler' ]];then
 yum -y remove openssh openssh-clients openssh-server 
 rm -rf /etc/ssh/*
 cd /usr/local/src/${OPENSSH_RELEASE}
./configure --prefix=/usr \
--sysconfdir=/etc/ssh \
--with-pam \
--with-ssl-dir=/usr/local/openssl \
--with-zlib=/usr/local/zlib
make -j 4 && make install
rm -f /etc/init.d/sshd
alias cp='cp'
cp -rf /usr/local/src/${OPENSSH_RELEASE}/contrib/redhat/sshd.init /etc/init.d/sshd
cp -rf /usr/local/src/${OPENSSH_RELEASE}/contrib/redhat/sshd.pam /etc/pam.d/sshd
chkconfig --add sshd
chkconfig sshd on
systemctl start sshd
chmod 600 /etc/ssh/*_key
cat << EOF >>/etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
EOF
systemctl restart sshd
elif [[ $ID == 'debian' || $ID == 'ubuntu' ]];then
apt -y remove ssh openssh-client openssh-server 
rm -rf /etc/ssh/*
OPENSSH_RELEASE=openssh-9.9p1
cd /usr/local/src/${OPENSSH_RELEASE}
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

main() {
	use_custom_mirrors $SERVER_IP $ID $VERSION 
  env_installer $ID $VERSION  
  file_download $SERVER_IP $ZLIB_RELEASE $OPENSSL_RELEASE $OPENSSH_RELEASE
  zlib_installer $ZLIB_RELEASE
  ssl_installer $ID $OPENSSL_RELEASE
  ssh_installer $ID $OPENSSH_RELEASE  
}

menu_list() {
incorrect_selection() {
  echo "选择有误，请重新选择！"
}

menu_option_one() {
  local SERVER_IP='100.201.3.111'
  if curl --connect-timeout 2 ${SERVER_IP} &> /dev/null
  then
  	main
  else
  	incorrect_selection
  fi  
}

menu_option_two() {
  local SERVER_IP='192.168.10.239'
  if curl --connect-timeout 2 ${SERVER_IP} &> /dev/null
  then
  	main
  else
  	incorrect_selection
  fi  
}

menu_option_three() {
  local SERVER_IP='100.0.0.239'
  if curl --connect-timeout 2 ${SERVER_IP} &> /dev/null
  then
  	main
  else
  	incorrect_selection
  fi  
}
press_anykey() {
  read -n 1 -r -s -p "Press any key to continue..."
  clear
}
until [ "$selection" = "0" ]; do
  clear
    cat<<_EOF_
    =====================================================
    ## 烟台市电子政务云OpenSSH升级脚本 V1.0
    ## zlib版本:      1.3.1
    ## openssl版本:   3.3.2
    ## openssh版本:   9.9p1
    -----------------------------------------------------
    ## 支持的操作系统
    ## AnolisOS 7/8/23
    ## KylinV10 SP2/SP3
    ## openEuler 20.03/22.04/24.03 lts
    ## Debian 11/12
    ## Ubuntu 20.04/22.04/24.04 lts
    -----------------------------------------------------
    ## 请输入服务器的所在区域:
    ## 
    ## (1) 国产化信创区域(含互联网、公共域、行政域)
    ## (2) X86 政务外网(公共服务域)
    ## (3) X86 行政服务域
    ##
    ## (0) 退出脚本
    -----------------------------------------------------
_EOF_
  echo -n "  请输入相应的数字: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_anykey ;;
    2 ) clear ; menu_option_two ; press_anykey ;;
    3 ) clear ; menu_option_three ; press_anykey ;;
    0 ) clear ; exit 0;;
    * ) clear ; incorrect_selection ; press_anykey ;;
  esac
done
}

menu_list
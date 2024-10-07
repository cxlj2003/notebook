#!/bin/bash
ZLIB_RELEASE=zlib-1.3.1
OPENSSL_RELEASE=openssl-3.3.2
OPENSSH_RELEASE=openssh-9.9p1

if [ ! -e /etc/os-release ];then
 echo '*** Cannot detect Linux distribution! Aborting.'
 exit 1
fi

env_installer() {
set -ex
local SERVER_IP=$1
local ID=$2
local VERSION=$3
if [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 7 ]];then
 echo 'anolis7.x'
 for repo in `ls /etc/yum.repos.d/ | egrep 'repo$'`;do 
  alias mv='mv' 
  mv -f /etc/yum.repos.d/$repo /etc/yum.repos.d/$repo.bak
 done
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
 yum -y install vim wget tar nano gcc make pam-devel perl perl-CPAN perl-IPC-Cmd 
 echo yes | cpan -i List::Util
elif [[ $ID == 'anolis' ]];then
 echo 'anolis>7.x'
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
elif [[ $ID == 'debian' ]];then
 echo debian
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
 apt -y install vim wget tar nano gcc make libpam0g-dev
elif [[ $ID == 'kylin' ]];then
 echo kylin
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd
elif [[ $ID == 'openEuler' ]];then
 echo openEuler
 yum -y install vim wget tar nano gcc make pam-devel perl perl-IPC-Cmd 
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
wget -nc -P ${WORKDIR}  ${OPENSSL_URL}/${OPENSSL_RELEASE}.tar.gz
wget -nc -P ${WORKDIR}   ${OPENSSH_URL}/${OPENSSH_RELEASE}.tar.gz
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

menu_option_one() {
  source /etc/os-release
  local SERVER_IP='100.201.3.111'
  env_installer $SERVER_IP $ID $VERSION  
  file_download $SERVER_IP $ZLIB_RELEASE $OPENSSL_RELEASE $OPENSSH_RELEASE
  zlib_installer $ZLIB_RELEASE
  ssl_installer $ID $OPENSSL_RELEASE
  ssh_installer $ID $OPENSSH_RELEASE  
  echo "信创升级openssh！完成"
}

menu_option_two() {
  source /etc/os-release
  local SERVER_IP='192.168.10.239'
  env_installer $SERVER_IP $ID $VERSION  
  file_download $SERVER_IP $ZLIB_RELEASE $OPENSSL_RELEASE $OPENSSH_RELEASE
  zlib_installer $ZLIB_RELEASE
  ssl_installer $ID $OPENSSL_RELEASE
  ssh_installer $ID $OPENSSH_RELEASE 
  echo "X86(政务外)升级openssh完成！"
}

menu_option_three() {
  source /etc/os-release
  local SERVER_IP='100.0.0.239'
  env_installer $SERVER_IP $ID $VERSION  
  file_download $SERVER_IP $ZLIB_RELEASE $OPENSSL_RELEASE $OPENSSH_RELEASE
  zlib_installer $ZLIB_RELEASE
  ssl_installer $ID $OPENSSL_RELEASE
  ssh_installer $ID $OPENSSH_RELEASE 
  echo "X86(行政服务域)升级openssh完成！"
}

press_enter() {
  echo ""
  echo -n "	Press Enter to continue !"
  read
  clear
}

incorrect_selection() {
  echo "Incorrect selection! Try again."
}

until [ "$selection" = "0" ]; do
  clear
  echo "************烟台市电子政务云************"
  echo "    将Openssl升级至3.3.2"
  echo "    将Openssh升级至9.9P1"
  echo "************支持操作系统列表************"
  echo "    AnolisOS 7.X 8.X 23.X"
  echo "    KylinV10 SP2 SP3"
  echo "    openEuler 24.03"
  echo "    Debian 11 12"
  echo "    Ubuntu 22.04 24.04"
  echo "    1  -  信创(互联网、政务外、行政服务域)"
  echo "    2  -  X86(政务外)"
  echo "    3  -  X86(行政服务域)"
  echo "    0  -  Exit"
  echo ""
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_enter ;;
    2 ) clear ; menu_option_two ; press_enter ;;
	3 ) clear ; menu_option_three ; press_enter ;;
    0 ) clear ; exit 0;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done
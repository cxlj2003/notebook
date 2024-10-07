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
local ID=$1
local VERSION=$2
if [[ $ID == 'anolis' && `echo $VERSION |awk -F . '{print $1}'` -eq 7 ]];then
 echo 'anolis7.x'
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

source /etc/os-release
env_installer $ID $VERSION

file_download() {
local ZLIB_URL=https://www.zlib.net
local OPENSSL_URL=https://www.openssl.org/source
local OPENSSH_URL=https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable
local WORKDIR=/usr/local/src
local ZLIB_RELEASE=$1
local OPENSSL_RELEASE=$2
local OPENSSH_RELEASE=$3
wget -nc -P ${WORKDIR} ${ZLIB_URL}/${ZLIB_RELEASE}.tar.gz 
wget -nc -P ${WORKDIR}  ${OPENSSL_URL}/${OPENSSL_RELEASE}.tar.gz
wget -nc -P ${WORKDIR}   ${OPENSSH_URL}/${OPENSSH_RELEASE}.tar.gz
}

file_download $ZLIB_RELEASE $OPENSSL_RELEASE $OPENSSH_RELEASE

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

zlib_installer $ZLIB_RELEASE

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

ssl_installer $ID $OPENSSL_RELEASE

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

ssh_installer $ID $OPENSSH_RELEASE

# 已测试操作系统

- AnolisOS7.9
- AnolisOS8.9
- AnolisOS23.1
- KylinV10SP2
- KylinV10SP3
- Debian12.7
- Ubuntu20.04lts
- OpenEuler
# 1. 安装Telnet服务器
## 1.1 AnolisOS/KylinV10/openEuler

```
#!/bin/bash
yum install vim wget tar nano -y
yum install telnet-server -y
yum install xinetd -y
cat <<EOF > /etc/xinetd.d/telnet
service telnet
{
    disable = no
    flags       = REUSE
    socket_type = stream       
    wait        = no
    user        = root
    server      = /usr/sbin/in.telnetd
    log_on_failure  += USERID
}
EOF
cat >> /etc/securetty <<EOF
pts/0
pts/1
pts/2
pts/3
pts/4
pts/5
pts/6
pts/7
pts/8
pts/9
pts/10
pts/11
pts/12
pts/13
pts/14
pts/15
EOF
systemctl stop firewalld
setenforce 0
systemctl start xinetd 
until ss -lnp |grep -E ':23'
do
	systemctl restart xinetd
done

```
## 1.2 Debian/Ubuntu

```
#!/bin/bash -e
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt -y install vim wget tar nano
apt -y install xinetd
apt -y install telnetd
if [ -e /usr/sbin/in.telnetd ]
then
cat >/etc/inetd.conf <<EOF
telnet stream tcp nowait telnetd /usr/sbin/tcpd /usr/sbin/in.telnetd
EOF
elif [ -e /usr/sbin/telnetd ]
then
cat >/etc/inetd.conf <<EOF
telnet stream tcp nowait telnetd /usr/sbin/tcpd /usr/sbin/telnetd
EOF
fi
cat << EOF > /etc/xinetd.d/telnet
service telnet
{
    disable = no
    flags       = REUSE
    socket_type = stream       
    wait        = no
    user        = root
EOF
if [ -e /usr/sbin/in.telnetd ]
then
cat << EOF >> /etc/xinetd.d/telnet
    server      = /usr/sbin/in.telnetd
EOF
elif [ -e /usr/sbin/telnetd ]
then
cat << EOF >> /etc/xinetd.d/telnet
    server      = /usr/sbin/telnetd
EOF
fi
cat << EOF >> /etc/xinetd.d/telnet
    log_on_failure  += USERID
}
EOF
if apt list |grep installed |grep ufw
then
	systemctl stop ufw
fi
systemctl stop apparmor
systemctl daemon-reload
systemctl start xinetd
until ss -lnp |grep -E ':23'
do
	systemctl restart xinetd
done
```


>后续步骤通过tenet登录目标服务器进行操作
# 2. 文件下载

```
ZLIB_RELEASE=zlib-1.3.1
OPENSSL_RELEASE=openssl-3.3.2
OPENSSH_RELEASE=openssh-9.9p1
wget -nc -P /usr/local/src https://www.zlib.net/${ZLIB_RELEASE}.tar.gz 
wget -nc -P /usr/local/src https://www.openssl.org/source/${OPENSSL_RELEASE}.tar.gz
wget -nc -P /usr/local/src  https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/${OPENSSH_RELEASE}.tar.gz
tar -zxvf /usr/local/src/${ZLIB_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSL_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSH_RELEASE}.tar.gz -C /usr/local/src/
```
# 3. 安装编译环境
## 3.1 AnolisOS/KylinV10/openEuler

```
#KylinV10
yum -y install gcc make pam-devel perl-IPC-Cmd perl-CPAN
echo yes |cpan List::Util
#yum -y install gcc gcc-c++ glibc make autoconf openssl openssl-devel pcre-devel pam-devel zlib-devel tcp_wrappers-devel tcp_wrappers libedit-devel perl-IPC-Cmd 
```

## 3.2 Debian/Ubuntu

```
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y gcc make libpam0g-dev
```

# 4.安装zlib
## AnolisOS/KylinV10/openEuler/Debian/Ubuntu

将zlib安装至/usr/local/zlib目录下
```
ZLIB_RELEASE=zlib-1.3.1
cd /usr/local/src/${ZLIB_RELEASE}
./configure --prefix=/usr/local/zlib
make -j 4 && make test && make install
cat <<EOF > /etc/ld.so.conf.d/zlib.conf
/usr/local/zlib/lib
EOF
ldconfig
```

# 5. 安装openssl
将openssl安装至/usr/local/openssl目录下
##  5.1 AnolisOS/KylinV10/openEuler

```
OPENSSL_RELEASE=openssl-3.3.2
cd /usr/local/src/${OPENSSL_RELEASE}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
#yum -y install perl-CPAN
#echo yes |cpan List::Util
#make clean
make -j 4 && make install
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
cat <<EOF > /etc/ld.so.conf.d/openssl_lib.conf
/usr/local/openssl/lib64
EOF
ldconfig
```

## 5.2 Debian/Ubuntu

```
OPENSSL_RELEASE=openssl-3.3.2
cd /usr/local/src/${OPENSSL_RELEASE}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
make -j 4 && make install
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
cat <<EOF > /etc/ld.so.conf.d/openssl_lib.conf
/usr/local/openssl/lib64
EOF
ldconfig
```

# 6. 安装openssh

安装说明详见源代码目录的INSTALL文件
## 6.1 AnolisOS/KylinV10/openEuler

```
#--without-openssl 
yum -y remove openssh openssh-clients openssh-server 
rm -rf /etc/ssh/*
OPENSSH_RELEASE=openssh-9.9p1
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
```
## 6.2 Debian/Ubuntu

```
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
```

# 7. 完整安装脚本
## 7.1 AnolisOS/KylinV10/openEuler

```
#!/bin/bash
#文件下载与解压
yum -y install tar wget
ZLIB_RELEASE=zlib-1.3.1
OPENSSL_RELEASE=openssl-3.3.2
OPENSSH_RELEASE=openssh-9.9p1
wget -nc -P /usr/local/src https://www.zlib.net/${ZLIB_RELEASE}.tar.gz 
wget -nc -P /usr/local/src https://www.openssl.org/source/${OPENSSL_RELEASE}.tar.gz
wget -nc -P /usr/local/src  https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/${OPENSSH_RELEASE}.tar.gz
tar -zxvf /usr/local/src/${ZLIB_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSL_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSH_RELEASE}.tar.gz -C /usr/local/src/
#安装编译环境
yum -y install gcc make pam-devel perl-IPC-Cmd perl-CPAN
echo yes |cpan List::Util
#安装zlib
ZLIB_RELEASE=zlib-1.3.1
cd /usr/local/src/${ZLIB_RELEASE}
./configure --prefix=/usr/local/zlib
make -j 4 && make test && make install
cat <<EOF > /etc/ld.so.conf.d/zlib.conf
/usr/local/zlib/lib
EOF
ldconfig
#安装openssl
OPENSSL_RELEASE=openssl-3.3.2
cd /usr/local/src/${OPENSSL_RELEASE}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
make -j 4 && make install
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
cat <<EOF > /etc/ld.so.conf.d/openssl_lib.conf
/usr/local/openssl/lib64
EOF
ldconfig
#安装openssh
yum -y remove openssh openssh-clients openssh-server 
rm -rf /etc/ssh/*
OPENSSH_RELEASE=openssh-9.9p1
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
systemctl daemon-reload
systemctl start sshd
chmod 600 /etc/ssh/*_key
cat << EOF >> /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
EOF
systemctl restart sshd
```
## 7.2 Debian/Ubuntu

```
#!/bin/bash
#文件下载与解压
ZZLIB_RELEASE=zlib-1.3.1
OPENSSL_RELEASE=openssl-3.3.2
OPENSSH_RELEASE=openssh-9.9p1
wget -nc -P /usr/local/src https://www.zlib.net/${ZLIB_RELEASE}.tar.gz 
wget -nc -P /usr/local/src https://www.openssl.org/source/${OPENSSL_RELEASE}.tar.gz
wget -nc -P /usr/local/src  https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/${OPENSSH_RELEASE}.tar.gz
tar -zxvf /usr/local/src/${ZLIB_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSL_RELEASE}.tar.gz -C /usr/local/src/
tar -zxvf /usr/local/src/${OPENSSH_RELEASE}.tar.gz -C /usr/local/src/
#安装编译环境
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y gcc make libpam0g-dev
#安装zlib
ZLIB_RELEASE=zlib-1.3.1
cd /usr/local/src/${ZLIB_RELEASE}
./configure --prefix=/usr/local/zlib
make -j 4 && make test && make install
cat <<EOF > /etc/ld.so.conf.d/zlib.conf
/usr/local/zlib/lib
EOF
ldconfig
#安装openssl
OPENSSL_RELEASE=openssl-3.3.2
cd /usr/local/src/${OPENSSL_RELEASE}
./config --prefix=/usr/local/openssl \
--with-zlib-lib=/usr/local/zlib/lib \
--with-zlib-include=/usr/local/zlib/include \
enable-md2 \
shared
make -j 4 && make install
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
cat <<EOF > /etc/ld.so.conf.d/openssl_lib.conf
/usr/local/openssl/lib64
EOF
ldconfig
#安装openssh
apt -y remove ssh openssh-client openssh-server 
rm -rf /etc/ssh/*
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
```

# 8. 验证安装并关闭telnet

```
openssl version
ssh -V
rm -rf /usr/local/src/*
systemctl disable telnet.socket --now
systemctl disable xinetd  --now
```
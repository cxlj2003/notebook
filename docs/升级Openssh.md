# 1. 安装Telnet服务器
## 1.1 CentOS/RHEL

```
#!/bin/bash
yum install xinetd telnet-server -y
cat <<EOF >/etc/xinetd.d/telnet
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
cat >>/etc/securetty <<EOF
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
systemctl start telnet.socket
```
## 1.2 Debian/Ubuntu

```
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt -y install xinetd telnetd
cat >/etc/inetd.conf <<EOF
telnet stream tcp nowait telnetd /usr/sbin/tcpd /usr/sbin/in.telnetd
EOF
cat <<EOF >/etc/xinetd.d/telnet
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
systemctl stop ufw
systemctl stop apparmor
systemctl start xinetd

```

[NOTE]>
>后续步骤通过tenet登录目标服务器进行操作
# 2. 文件下载

```
wget -P /usr/local/src -O zlib.tar.gz https://www.zlib.net/zlib-1.3.1.tar.gz 
wget -P /usr/local/src -O openssl.tar.gz https://github.com/openssl/openssl/releases/download/openssl-3.3.2/openssl-3.3.2.tar.gz
wget -P /usr/local/src -O openssh.tar.gz  https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/openssh-9.9p1.tar.gz
```
# 3. 编译环境准备
## 3.1 CentOS/RHEL

```
yum -y install vim gcc gcc-c++ glibc make autoconf openssl openssl-devel pcre-devel pam-devel zlib-devel tcp_wrappers-devel tcp_wrappers libedit-devel perl-IPC-Cmd wget tar lrzsz nano

```

## 3.2 Debian/Ubuntu

```
apt update
apt install -y gcc make
```

# 4.安装zlib

## 4.1 CentOS/RHEL

```


```
## 4.2 Debian/Ubuntu

```


```
# 5. 安装openssl

## 5.1 CentOS/RHEL

```


```

## 5.2 Debian/Ubuntu

```


```
# 6. 安装openssh

## 6.1 CentOS/RHEL

```
yum -y remove openssh openssh-clients openssh-server 

```
## 6.2 Debian/Ubuntu

```
apt -y remove ssh openssh-clients openssh-server 

```

# 7. 完整安装脚本
## 7.1 CentOS/RHEL

```

```
## 7.2 Debian/Ubuntu

```


```
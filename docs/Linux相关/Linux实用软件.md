# 1. 端口转发
## 1.1使用`rinetd`

### 1)安装

```
# 红帽系
yum install rinetd -y
# 德班系
apt install rinetd -y
```
### 2)修改配置文件

配置文件为/etc/rinetd.conf
```
cat  << EOF > /etc/rinetd.conf
# allow 192.168.2.* 
# deny 192.168.1.* 
# bindadress bindport connectaddress connectport 
# 0.0.0.0 8000      127.0.0.1 80
# 0.0.0.0 8000/udp  127.0.0.1 80/udp
#logfile /var/log/rinetd.log
EOF
```

### 3)创建服务

```
cat << EOF > /lib/systemd/system/rinetd.service
[Unit]
Description=Rinetd Internet TCP/UDP redirection server
Documentation=man:rinetd(8)
Wants=network-online.target
After=network-online.target local-fs.target remote-fs.target

[Service]
Type=forking
ExecStart=/usr/sbin/rinetd -c /etc/rinetd.conf
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/rinetd.pid

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable rinetd.service --now
```
## 1.2 使用`SSH`

### 1)本地转发

格式:
```
ssh -L [local_host]:[local_port]:[remote_host]:[remote_port] [sshserver]
```
示例:
客户端:198.19.201.138;服务器:198.19.201.119;跳板机:198.19.201.162
在客户端连接跳板机
```
ssh -L 0.0.0.0:22022:198.19.201.119:22 198.19.201.162
```

同局域网的客户端可以通过访问198.19.201.138:22022跳转至198.19.201.119:22.

### 2)远程转发

格式:
```
ssh -R [local_host]:[local_port]:[remote_host]:[remote_port] [sshclient]
```
示例:
客户端:198.19.201.138;服务器:198.19.201.119;跳板机:198.19.201.162
在跳板机连接客户端:
```
ssh -R 0.0.0.0:22022:198.19.201.119:22 198.19.201.138
```

同局域网的客户端可以通过访问198.19.201.138:22022跳转至198.19.201.119:22.

>[!NOTE]
>说明:
>1.本地转发时客户端连接跳板机;远程转发时跳板机连接客户端.
>2.实现的目的都是本地客户端通过本地客户端连接远程服务器


# 2. screen

```
screen -S yourname -> 新建一个叫yourname的session
screen -ls -> 列出当前所有的session
screen -r yourname -> 回到yourname这个session
screen -d yourname -> 远程detach某个session
screen -d -r yourname -> 结束当前session并回到yourname这个session
```

# 3.qemu-img

```

qemu-img convert -f qcow2 ecs-inlinux23.12-x64-20240425.qcow2 -O raw ecs-inlinux23.12-x64-20240425.img
qemu-img convert -f qcow2 ecs-inlinux23.12-x64-20240425.qcow2 -O vmdk ecs-inlinux23.12-x64-20240425.vmdk

```
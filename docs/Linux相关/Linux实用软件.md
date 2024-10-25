# 1. 端口转发
## 1.1 rinetd

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
## 1.2 socat

```

```
# 2. screen

```
screen -S yourname -> 新建一个叫yourname的session
screen -ls -> 列出当前所有的session
screen -r yourname -> 回到yourname这个session
screen -d yourname -> 远程detach某个session
screen -d -r yourname -> 结束当前session并回到yourname这个session
```

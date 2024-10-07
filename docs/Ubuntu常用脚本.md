1. 修改apt源
- 20.04LTS及以前版本
```

url=`cat /etc/apt/sources.list|egrep -v "#"|awk -F "/" '{print $3}'|uniq`;for i in $url;do sed -i "s/$i/mirrors.ustc.edu.cn/g" /etc/apt/sources.list;done

```
- 24.04版本
```

url=`cat /etc/apt/sources.list.d/ubuntu.sources|egrep -v "#"|egrep -v "key"|awk -F "/" '{print $3}'|uniq`;for i in $url;do sed -i "s/$i/mirrors.ustc.edu.cn/g" /etc/apt/sources.list.d/ubuntu.sources;done

```
2. IP地址配置

```

rm -rf /etc/netplan/*
declare -a NIC
NIC=`ip route | egrep -v "br|docker|default" | egrep "eth|ens|enp"|awk '{print $3}'` 
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
3. 内核模块

```
#查看模块
lsmod 
#加载模块
modprobe <modname>
#卸载模块
rmmod <modmanme>
```
	开机预加载模块
```
cat <<EOF > /etc/modules-load.d/pre-load.conf
tun
EOF
```
4. 
5. screen软件使用
```
screen -S yourname -> 新建一个叫yourname的session
screen -ls -> 列出当前所有的session
screen -r yourname -> 回到yourname这个session
screen -d yourname -> 远程detach某个session
screen -d -r yourname -> 结束当前session并回到yourname这个session
```
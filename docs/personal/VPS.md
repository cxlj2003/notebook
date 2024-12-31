# 1.基础软件

```
apt install lrzsz wget curl git -y 
```
安装Docker-CE
```
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```
# 2.系统设置

```
systemctl disable ufw --now
systemctl mask ufw
systemctl disable apparmor --now
systemctl mask apparmor
rm -rf /etc/localtime
ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```
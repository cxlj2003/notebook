# 1. 端口转发
## 1.1 rinetd

```
wget https://github.com/samhocevar/rinetd/releases/download/v0.73/rinetd-0.73.tar.gz
tar -zxvf rinetd-0.73.tar.gz
cd rinetd-0.73
./bootstrap
./configure
make && make install


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

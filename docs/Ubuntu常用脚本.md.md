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


```
4. screen软件使用
```
screen -S yourname -> 新建一个叫yourname的session
screen -ls -> 列出当前所有的session
screen -r yourname -> 回到yourname这个session
screen -d yourname -> 远程detach某个session
screen -d -r yourname -> 结束当前session并回到yourname这个session
```
1. 修改apt源
- 20.04LTS及以前版本
```

url=`cat /etc/apt/sources.list|egrep -v "#"|awk -F "/" '{print $3}'|uniq`;for i in $url;do sed -i "s/$i/mirrors.ustc.edu.cn/g" /etc/apt/sources.list;done

```
- 24.04版本
```


```

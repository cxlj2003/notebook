# 1. 版权信息

```
cat <<_EOF_

_EOF_
```
#  2. 菜单

```
#!/bin/bash
menu_list() {
##选择错误重新选择
incorrect_selection() {
  echo "Incorrect selection! Try again."
}

menu_option_one() {
  if [[  ]]
  then
	  echo "Option One!"
  else
	  incorrect_selection
  fi
}

menu_option_two() {
  if [[  ]]
  then
	  echo "Option two!"
  else
	  incorrect_selection
  fi
}

menu_option_three() {
  if [[  ]]
  then
	  echo "Option three!"
  else
	  incorrect_selection
  fi
}

press_anykey() {
  read -n 1 -r -s -p "Press any key to continue..."
  clear
}

until [ "$selection" = "0" ]; do
    clear
    cat<<_EOF_
    ==============================
    Menusystem experiment
    ------------------------------
    Please enter your choice:

    Option (1)
    Option (2)
    Option (3)
           (0) Quit
    ------------------------------
_EOF_
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_anykey ;;
    2 ) clear ; menu_option_two ; press_anykey ;;
    3 ) clear ; menu_option_three ; press_anykey ;;
    0 ) clear ; exit 0;;
    * ) clear ; incorrect_selection ; press_anykey ;;
  esac
done
}
menu_list
```

# 3.判断操作系统类型

```
get_os_type() {
if [ ! -e /etc/os-release ];then
  echo 'Unable get linux distribution !'
fi
source /etc/os-release
echo $ID
}
get_os_type
```

```
get_os_versionid() {
if [ ! -e /etc/os-release ];then
  echo 'Unable get linux distribution !'
fi
source /etc/os-release
echo $VERSION_ID
}
get_os_versionid
```

# 4. 获取所有网卡名称

```
get_netdev_names() {
	lshw -C network -businfo  |awk '/(E|e)thernet (C|c)ontroller/{print $2}' |xargs
}
get_netdev_names
```

```
get_active_netdev_names() {
	local All_NICs=$(lshw -C network -businfo  |awk '/(E|e)thernet (C|c)ontroller/{print $2}' |xargs)
	for i in ${All_NICs}
	do
		if ip link show $i |grep LOWER_UP &> /dev/null
		then
				echo $i
		fi
	done	
}
get_active_netdev_names |xargs
```

# 5. 读取文件中的行

```
get_lines() {
	local file=$1
	cat $file | while read line
		do
			echo $line
		done
}
```

# 6. 
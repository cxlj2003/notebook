#!/bin/bash -e
if [ ! -e /etc/os-release ];then
 echo '*** Cannot detect Linux distribution! Aborting.'
 exit 1
fi
source /etc/os-release
if [[ $ID == 'anolis' ]];then
 echo anolis
elif [[ $ID == 'kylin' ]];then
 echo kylin
fi

#!/bin/bash
set -ex

yum_server_list='
100.201.3.111
100.0.0.239
192.168.10.239
'

set_osrelease(){	
if [ ! -e /etc/os-release ];then
 echo 'Cannot detect Linux distribution! Aborting.'
 exit 1
else
 source /etc/os-release
fi
}

use_custom_mirrors(){
local yum_server=$1
local os_type=${ID}
local os_version_id=${VERSION_ID}

if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 for repo in `ls /etc/yum.repos.d/ | egrep 'repo$'`;do 
  alias mv='mv' 
  mv -f /etc/yum.repos.d/${repo} /etc/yum.repos.d/${repo}.bak
 done
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
 for list in `ls /etc/apt/ |egrep 'list$'`;do
 	alias mv='mv'
 	mv -f /etc/apt/${list} /etc/apt/${list}.bak
 done
 for source in `ls /etc/apt/sources.list.d/ |egrep 'sources$'`;do
 	alias mv='mv'
 	mv -f /etc/apt/sources.list.d/${source} /etc/apt/sources.list.d/${source}.bak 	
 done
fi
if [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 7 ]];then 
 cat << EOF > /etc/yum.repos.d/AnolisOS-os.repo
[os]
name=AnolisOS-\$releasever - os
baseurl=http://${yum_server}/anolis/\$releasever/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-extras.repo
[extras]
name=AnolisOS-\$releasever - extras
baseurl=http://${yum_server}/anolis/\$releasever/extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-updates.repo
[updates]
name=AnolisOS-\$releasever - updates
baseurl=http://${yum_server}/anolis/\$releasever/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 8 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS-AppStream.repo
[AppStream]
name=AnolisOS-\$releasever - AppStream
baseurl=http://${yum_server}/anolis/\$releasever/AppStream/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-BaseOS.repo
[BaseOS]
name=AnolisOS-\$releasever - BaseOS
baseurl=http://${yum_server}/anolis/\$releasever/BaseOS/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-Extras.repo
[Extras]
name=AnolisOS-\$releasever - Extras
baseurl=http://${yum_server}/anolis/\$releasever/Extras/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-PowerTools.repo
[PowerTools]
name=AnolisOS-\$releasever - PowerTools
baseurl=http://${yum_server}/anolis/\$releasever/PowerTools/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
cat << EOF > /etc/yum.repos.d/AnolisOS-kernel-5.10.repo
[kernel-5.10]
name=AnolisOS-\$releasever - Kernel 5.10
baseurl=http://${yum_server}/anolis/\$releasever/kernel-5.10/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'anolis' && `echo ${os_version_id} |awk -F . '{print $1}'` -eq 23 ]];then
cat << EOF > /etc/yum.repos.d/AnolisOS.repo 
[os]
name=AnolisOS-\$releasever - os
baseurl=http://${yum_server}/anolis/\$releasever/os/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[updates]
name=AnolisOS-\$releasever - updates
baseurl=http://${yum_server}/anolis/\$releasever/updates/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0

[kernel-6]
name=AnolisOS-\$releasever - kernel-6
baseurl=http://${yum_server}/anolis/\$releasever/kernel-6/\$basearch/os
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ANOLIS
gpgcheck=0
EOF
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Tercel |wc -l` -gt 0 ]];then
local sub_version=SP1
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-os
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os
enabled = 1
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-updates
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates
enabled = 1
EOF
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Sword |wc -l` -gt 0 ]];then
local sub_version=SP2
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-os
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os
enabled = 1
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-updates
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates
enabled = 1
EOF
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Lance |wc -l` -gt 0 ]];then
local sub_version=SP3
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-os
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-os
enabled = 1
[zwc-${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates]
name = zwc KylinV10 ${sub_version}_$(uname -i) adv-updates
baseurl = ${yum_server}/${ID}_${VERSION_ID}_${sub_version}_$(uname -i)-adv-updates
enabled = 1
EOF
'''
{
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Tercel |wc -l` -gt 0 ]];then
local sub_version=SP1
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server ${os_version_id} - Os 
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/base/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server ${os_version_id} - Updates
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/updates/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server ${os_version_id} - Addons
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/addons/\$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Sword |wc -l` -gt 0 ]];then
local sub_version=SP2
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server ${os_version_id} - Os 
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/base/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server ${os_version_id} - Updates
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/updates/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server ${os_version_id} - Addons
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/addons/\$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
elif [[ ${os_type} == 'kylin' && `cat /etc/os-release |grep Lance |wc -l` -gt 0 ]];then
local sub_version=SP3
cat << EOF > /etc/yum.repos.d/kylin_$(uname -i).repo
###Kylin Linux Advanced Server 10 - os repo###

[ks10-adv-os]
name = Kylin Linux Advanced Server ${os_version_id} - Os 
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/base/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-updates]
name = Kylin Linux Advanced Server ${os_version_id} - Updates
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/updates/\$basearch/
gpgcheck = 0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 1

[ks10-adv-addons]
name = Kylin Linux Advanced Server ${os_version_id} - Addons
baseurl = http://${yum_server}/${os_type}/NS/${os_version_id}/${os_version_id}${sub_version}/os/adv/lic/addons/\$basearch/
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kylin
enabled = 0
EOF
}
'''
elif [[ ${os_type} == 'openEuler' ]];then
local sub_version=`cat /etc/os-release |awk -F \" '/VERSION=/{print $(NF-1)}' |sed -e 's/(//g' -e 's/)//g' -e 's/ /-/g'`
cat << EOF > /etc/yum.repos.d/openEuler.repo
[OS]
name=OS
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/OS'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[everything]
name=everything
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/everything/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/everything'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/everything/\$basearch/RPM-GPG-KEY-openEuler

[EPOL]
name=EPOL
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/EPOL/main/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/EPOL/main'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[debuginfo]
name=debuginfo
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/debuginfo/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/debuginfo'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/debuginfo/\$basearch/RPM-GPG-KEY-openEuler

[source]
name=source
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever'&'arch=source
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/RPM-GPG-KEY-openEuler

[update]
name=update
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/update/\$basearch/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/update'&'arch=\$basearch
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/OS/\$basearch/RPM-GPG-KEY-openEuler

[update-source]
name=update-source
baseurl=http://${yum_server}/${os_type}/openEuler-${sub_version}/update/source/
#metalink=http://${yum_server}/${os_type}/metalink?repo=\$releasever/update'&'arch=source
#metadata_expire=1h
enabled=1
gpgcheck=0
gpgkey=http://${yum_server}/${os_type}/openEuler-${sub_version}/source/RPM-GPG-KEY-openEuler
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'buster' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ buster main contrib non-free
deb-src http://${yum_server}/debian/ buster main contrib non-free

deb http://${yum_server}/debian/ buster-updates main contrib non-free
deb-src http://${yum_server}/debian/ buster-updates main contrib non-free

deb http://${yum_server}/debian/ buster-backports main contrib non-free
deb-src http://${yum_server}/debian/ buster-backports main contrib non-free

deb http://${yum_server}/debian-security/ buster/updates main contrib non-free
deb-src http://${yum_server}/debian-security/ buster/updates main contrib non-free
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'bullseye' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ bullseye main contrib non-free
deb-src http://${yum_server}/debian/ bullseye main contrib non-free

deb http://${yum_server}/debian/ bullseye-updates main contrib non-free
deb-src http://${yum_server}/debian/ bullseye-updates main contrib non-free

deb http://${yum_server}/debian/ bullseye-backports main contrib non-free
deb-src http://${yum_server}/debian/ bullseye-backports main contrib non-free

deb http://${yum_server}/debian-security/ bullseye-security main contrib non-free
deb-src http://${yum_server}/debian-security/ bullseye-security main contrib non-free
EOF
elif [[ ${os_type} == 'debian' && ${VERSION_CODENAME} == 'bookworm' ]];then
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm main contrib non-free non-free-firmware

deb http://${yum_server}/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm-updates main contrib non-free non-free-firmware

deb http://${yum_server}/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian/ bookworm-backports main contrib non-free non-free-firmware

deb http://${yum_server}/debian-security/ bookworm-security main contrib non-free non-free-firmware
deb-src http://${yum_server}/debian-security/ bookworm-security main contrib non-free non-free-firmware
EOF
elif [[ ${os_type} == 'ubuntu' ]];then
: '
cat << EOF > /etc/apt/sources.list
deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME} main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-security main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-updates main restricted universe multiverse

deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse
deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-backports main restricted universe multiverse

## Not recommended
# deb http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
# deb-src http://${yum_server}/ubuntu/ ${VERSION_CODENAME}-proposed main restricted universe multiverse
EOF
'
cat << EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://${yum_server}/ubuntu
Suites: ${VERSION_CODENAME} ${VERSION_CODENAME}-updates ${VERSION_CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://${yum_server}/ubuntu
Suites: ${VERSION_CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
fi
if [[ ${os_type} == 'anolis' || ${os_type} == 'kylin' || ${os_type} == 'openEuler' ]];then
 yum clean all 
 yum makecache
elif [[ ${os_type} == 'debian' || ${os_type} == 'ubuntu' ]];then
 export DEBIAN_FRONTEND=noninteractive
 apt -y update
fi

}

for yum_server in ${yum_server_list};do
 if curl --connect-timeout 2 ${yum_server} &> /dev/null ;then
 set_osrelease
 use_custom_mirrors ${yum_server} ${os_type} ${os_version_id}
 break
 else
 continue
 fi 
done

set +ex
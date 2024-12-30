# 1.前提条件

- 两台或多台具有公网IP的服务器
- 操作系统建议使用ubuntu
- 安装Docker和Docker-compose

```
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

# 2.首个节点

```
## 创建工作目录
if [ ! -e /data/ztncui ];then
mkdir -p /data/ztncui
fi
## 创建配置文件
cat << EOF > /data/ztncui/docker-compose.yaml
services:
  ztncui:
    image:  keynetworks/ztncui
    network_mode: host
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    container_name: ztncui
    hostname: ztncui
    environment:
      - NODE_ENV=production
      - HTTP_ALL_INTERFACES=yes
      - HTTP_PORT=3000
      - ZTNCUI_PASSWD=password
    volumes:
      - ./etc:/opt/key-networks/ztncui/etc
      - ./zerotier-one:/var/lib/zerotier-one
    restart: always
EOF
## 启动容器
cd /data/ztncui && docker compose up -d

```

创建网络并导出控制器配置
```
cd /data/ztncui/zerotier-one
tar -cvf controller.d.tar controller.d
```

记录公钥用于客户端文件编译
```
cat /data/ztncui/zerotier-one/identity.public
```

# 3.其他节点


```
## 创建工作目录
if [ ! -e /data/ztncui ];then
mkdir -p /data/ztncui
fi
## 创建配置文件
cat << EOF > /data/ztncui/docker-compose.yaml
services:
  ztncui:
    image:  keynetworks/ztncui
    network_mode: host
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    container_name: ztncui
    hostname: ztncui
    environment:
      - NODE_ENV=production
      - HTTP_ALL_INTERFACES=yes
      - HTTP_PORT=3000
      - ZTNCUI_PASSWD=password
    volumes:
      - ./etc:/opt/key-networks/ztncui/etc
      - ./zerotier-one:/var/lib/zerotier-one
    restart: always
EOF
## 启动容器
cd /data/ztncui && docker compose up -d
```

导入网络控制器配置
```
cd /data/ztncui/zerotier-one
mv controller.d controller.d.bak
tar -xvf controller.d.tar
docker compose restart
```

记录公钥用于客户端文件编译
```
cat /data/ztncui/zerotier-one/identity.public
```

# 4.编译`planet`

```
apt -y install git unzip

## 创建工作目录
if [ ! -e /data/zt1-planet-maker ];then
mkdir -p /data/zt1-planet-maker
fi
cd /data/zt1-planet-maker
git clone -b dev https://github.com/zerotier/ZeroTierOne.git
cd /data/zt1-planet-maker/ZeroTierOne/attic/world
## 
```

修改`planet root`的配置文件
```
cat << EOF >/data/zt1-planet-maker/ZeroTierOne/attic/world/mkworld.cpp
/*
 * ZeroTier One - Network Virtualization Everywhere
 * Copyright (C) 2011-2016  ZeroTier, Inc.  https://www.zerotier.com/
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * This utility makes the World from the configuration specified below.
 * It probably won't be much use to anyone outside ZeroTier, Inc. except
 * for testing and experimentation purposes.
 *
 * If you want to make your own World you must edit this file.
 *
 * When run, it expects two files in the current directory:
 *
 * previous.c25519 - key pair to sign this world (key from previous world)
 * current.c25519 - key pair whose public key should be embedded in this world
 *
 * If these files do not exist, they are both created with the same key pair
 * and a self-signed initial World is born.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <string>
#include <vector>
#include <algorithm>

#include <node/Constants.hpp>
#include <node/World.hpp>
#include <node/C25519.hpp>
#include <node/Identity.hpp>
#include <node/InetAddress.hpp>
#include <osdep/OSUtils.hpp>

using namespace ZeroTier;

int main(int argc,char **argv)
{
	std::string previous,current;
	if ((!OSUtils::readFile("previous.c25519",previous))||(!OSUtils::readFile("current.c25519",current))) {
		C25519::Pair np(C25519::generate());
		previous = std::string();
		previous.append((const char *)np.pub.data,ZT_C25519_PUBLIC_KEY_LEN);
		previous.append((const char *)np.priv.data,ZT_C25519_PRIVATE_KEY_LEN);
		current = previous;
		OSUtils::writeFile("previous.c25519",previous);
		OSUtils::writeFile("current.c25519",current);
		fprintf(stderr,"INFO: created initial world keys: previous.c25519 and current.c25519 (both initially the same)" ZT_EOL_S);
	}

	if ((previous.length() != (ZT_C25519_PUBLIC_KEY_LEN + ZT_C25519_PRIVATE_KEY_LEN))||(current.length() != (ZT_C25519_PUBLIC_KEY_LEN + ZT_C25519_PRIVATE_KEY_LEN))) {
		fprintf(stderr,"FATAL: previous.c25519 or current.c25519 empty or invalid" ZT_EOL_S);
		return 1;
	}
	C25519::Pair previousKP;
	memcpy(previousKP.pub.data,previous.data(),ZT_C25519_PUBLIC_KEY_LEN);
	memcpy(previousKP.priv.data,previous.data() + ZT_C25519_PUBLIC_KEY_LEN,ZT_C25519_PRIVATE_KEY_LEN);
	C25519::Pair currentKP;
	memcpy(currentKP.pub.data,current.data(),ZT_C25519_PUBLIC_KEY_LEN);
	memcpy(currentKP.priv.data,current.data() + ZT_C25519_PUBLIC_KEY_LEN,ZT_C25519_PRIVATE_KEY_LEN);

	// =========================================================================
	// EDIT BELOW HERE

	std::vector<World::Root> roots;

	const uint64_t id = ZT_WORLD_ID_EARTH;
	const uint64_t ts = 1567191349589ULL; // August 30th, 2019

       // 1                                                                                                                                                              
        roots.push_back(World::Root());                                                                                                                                   
        roots.back().identity = Identity("9464df2878:0:70cc929d0b6389414f96a321895ad73f12c49066d301c9ad0ca606562f24b86074dac65ec1e5daeab3f92126acfd64a7a6ebfdcdf75aa33850cce7dc380920cc");
        roots.back().stableEndpoints.push_back(InetAddress("43.199.62.154/9993"));                                                                                                        
                                                                                                                                                                                          
        // 2                                                                                                                                                                              
        roots.push_back(World::Root());                                                                                                                                                   
        roots.back().identity = Identity("65aa3551b0:0:5e9843642062b38662c1fff59ea5bc469026934f28f2fef96c573f46f8c34b2a9bc3fa8dc159fe00561f82effcaa3cb3031621e0cc8c06978bd8aa3d16d31219");
        roots.back().stableEndpoints.push_back(InetAddress("144.123.23.124/9993"));                                                                                                       
                                                                                                                                                                                          
        // 3                                                                                                                                                                              
        roots.push_back(World::Root());                                                                                                                                                   
        roots.back().identity = Identity("0063d09ecf:0:4eb4982b677f0475e7188f454ee921d80ddb8d17b38f0475a944aeea2ca3280a223a864f13d53d5c0debc2b7ad21785532303af9215158ea6bd6fafad7e9ab75");
        roots.back().stableEndpoints.push_back(InetAddress("103.143.230.141/9993"));                                                                                                      
                                                                                                                                                                                          
        // 4                                                                                                                                                                              
        roots.push_back(World::Root());                                                                                                                                                   
        roots.back().identity = Identity("33f185f973:0:225484fb619bef29b66f4acb70e77e5394521391ec3724d720e05b536b0a2f02061b58974d7e22315215eae1b3dc4c748ca6e51e417e756a3e0620a031bb2c16");
        roots.back().stableEndpoints.push_back(InetAddress("107.172.99.138/9993"));      


	// END WORLD DEFINITION
	// =========================================================================

	fprintf(stderr,"INFO: generating and signing id==%llu ts==%llu" ZT_EOL_S,(unsigned long long)id,(unsigned long long)ts);

	World nw = World::make(World::TYPE_PLANET,id,ts,currentKP.pub,roots,previousKP);

	Buffer<ZT_WORLD_MAX_SERIALIZED_LENGTH> outtmp;
	nw.serialize(outtmp,false);
	World testw;
	testw.deserialize(outtmp,0);
	if (testw != nw) {
		fprintf(stderr,"FATAL: serialization test failed!" ZT_EOL_S);
		return 1;
	}

	OSUtils::writeFile("world.bin",std::string((const char *)outtmp.data(),outtmp.size()));
	fprintf(stderr,"INFO: world.bin written with %u bytes of binary world data." ZT_EOL_S,outtmp.size());

	fprintf(stdout,ZT_EOL_S);
	fprintf(stdout,"#define ZT_DEFAULT_WORLD_LENGTH %u" ZT_EOL_S,outtmp.size());
	fprintf(stdout,"static const unsigned char ZT_DEFAULT_WORLD[ZT_DEFAULT_WORLD_LENGTH] = {");
	for(unsigned int i=0;i<outtmp.size();++i) {
		const unsigned char *d = (const unsigned char *)outtmp.data();
		if (i > 0)
			fprintf(stdout,",");
		fprintf(stdout,"0x%.2x",(unsigned int)d[i]);
	}
	fprintf(stdout,"};" ZT_EOL_S);

	return 0;
}

EOF
```

编译`planet`
```
## 应用配置文件
source build.sh
## 编译planet
./mkworld
```

# 5.替换`planet`

`Windows`
```
C:\ProgramData\ZeroTier\One
```

`Linux`
```
/var/lib/zerotier-one
```

>[!NOTE]
>所有节点均需要更换planet文件


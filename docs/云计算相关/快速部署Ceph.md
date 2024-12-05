# 1. Cephadm

## 1.1 操作系统

Ubuntu 24.01LTS
## 1.2 先决条件

- Python 3
    
- Systemd
    
- Podman or Docker for running containers
    
- Time synchronization 
    
- LVM2 for provisioning storage devices

## 1.3 安装cephadm

```
apt install cephadm=19.2.0-0ubuntu0.24.04.1 -y 
```

## 1.4 Ceph容器镜像

[https://quay.io/repository/ceph/ceph](https://quay.io/repository/ceph/ceph) [https://hub.docker.com/r/ceph](https://hub.docker.com/r/ceph)

```
docker pull quay.io/ceph/ceph:v19.2.0
```
# 2. 
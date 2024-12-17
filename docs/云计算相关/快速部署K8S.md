# 1. 使用kubeadm

## 1.1 安装依赖

```


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sysctl net.ipv4.ip_forward
```

修改`kubeadm`镜像源
```
kubeadm config print init-defaults > kubeadm.conf
imageRepository: registry.aliyuncs.com/google_containers
kubeadm config images pull --config kubeadm.conf
```

## 1.2 安装`kubadm,kubectl,kublet`

```
apt-get update && apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt update
apt install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl
```

## 1.3 初始化主节点

```
kubeadm init --image-repository registry.aliyuncs.com/google_containers
```
# 2. 使用kind

用于测试
当前版本:`v0.25.0`
https://github.com/kubernetes-sigs/kind/releases
默认节点镜像现在是:
```
kindest/node:v1.31.2@sha256:18fbefc20a7113353c7b75b5c869d7145a6abd6269154825872dc59c1329912e
```

## 2.1 先决条件



```

```
## 2.2 安装kind

```
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## 2.3 使用kind

创建群集,群集默认名称为kind;
```
kind create cluster # Default cluster context name is `kind`.
kind create cluster --name kind-2
```

查看群集;
```
kind get clusters
```

与指定群集交互
```
kubectl cluster-info --context kind-kind
kubectl cluster-info --context kind-kind-2
```

删除群集
```
kind delete cluster #删除默认群集
kind delete cluster --name kind-2
```

将映像加载到集群中
```
kind load docker-image my-custom-image-0 my-custom-image-1
kind load docker-image my-custom-image-0 my-custom-image-1 --name kind-kind-2
```
``
配置已有集群
```
wget https://raw.githubusercontent.com/kubernetes-sigs/kind/main/site/content/docs/user/kind-example-config.yaml
kind create cluster --config kind-example-config.yaml
```

多节点群集
```
cat << EOF > multi-node.yaml
# three node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

控制层面HA
```
cat << EOF > control-plane-ha.yaml
# a cluster with 3 control-plane nodes and 3 workers
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: control-plane
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF
```

将端口映射着主机
```
cat << EOF > map-port-host.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0" # Optional, defaults to "0.0.0.0"
    protocol: udp # Optional, defaults to tcp
EOF
```

指定k8s的版本
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.16.4@sha256:b91a2c2317a000f3a783489dfb755064177dbc3a0b2f4147d50f04825d016f55
- role: worker
  image: kindest/node:v1.16.4@sha256:b91a2c2317a000f3a783489dfb755064177dbc3a0b2f4147d50f04825d016f55
```

启用gates特性
```
cat << EOF > feature.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  FeatureGateName: true
EOF
```

导出集群日志
```
kind export logs
```

# 3. kubesphere

## 3.1 


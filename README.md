## Quick Start

展示 skaffold+docker+kind 容器化部署的demo

```bash
kind create cluster --name test
skaffold config set --global local-cluster true
```

kind常见命令：https://kind.sigs.k8s.io/docs/user/quick-start/#creating-a-cluster

查看当前所有的kind集群：

```bash
$ kind get clusters
kind
test
```

设置kubectl的上下文，以便与特定的集群交互。集群名称为`kind-xxxx`：

```bash
kubectl cluster-info --context kind-test
```

将服务部署到本地：

```bash
skaffold dev
```

成功部署之后，需要设置端口转发，把本地机器的 3000 端口与 Kubernetes 集群中`web`服务的 3000 端口进行绑定

```bash
kubectl port-forward service/web 3000:3000
```

然后就可以在浏览器中访问：http://localhost:3000






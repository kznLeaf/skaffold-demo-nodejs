## Quick Start

用下面的命令创建 k8s 集群，包含一个控制平面和两个工作节点

```bash
kind create cluster --name test --config kind-example-config.yaml
```

告诉 skaffold 操作本地集群

```bash
skaffold config set --global local-cluster true
```

kind常见命令：https://kind.sigs.k8s.io/docs/user/quick-start/#creating-a-cluster

查看当前所有的kind集群：

```bash
$ kind get clusters
kind
test
```

最好指定`kubectl`的上下文为特定的集群（注意`kind`仍然使用默认的集群）

```bash
kubectl cluster-info --context kind-test
```

常用查询命令：

```bash
kubectl get nodes # 查询当前集群中的节点状态
kind get nodes  --name test # 和上一条命令的作用相同，但需要指定集群，查询结果也更加简略
```

**集群中的节点，就是 docker 中正在运行的容器**。从下面两条命令的执行结果就可以看出来：

```bash
$ kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
test-control-plane   Ready    control-plane   12m   v1.34.0
test-worker          Ready    <none>          12m   v1.34.0
test-worker2         Ready    <none>          12m   v1.34.0

$ docker ps
CONTAINER ID   IMAGE                  COMMAND                   CREATED          STATUS          PORTS                       NAMES
c510612390ac   kindest/node:v1.34.0   "/usr/local/bin/entr…"   18 minutes ago   Up 18 minutes                               test-worker
d95ae784bff2   kindest/node:v1.34.0   "/usr/local/bin/entr…"   18 minutes ago   Up 18 minutes                               test-worker2
7530f89aa073   kindest/node:v1.34.0   "/usr/local/bin/entr…"   18 minutes ago   Up 18 minutes   127.0.0.1:33603->6443/tcp   test-control-plane
```

## 部署

将服务部署到本地：

```bash
skaffold dev
```

成功部署之后，需要设置端口转发，把本地机器的 3000 端口与 Kubernetes 集群中`web`服务的 3000 端口进行绑定

```bash
kubectl port-forward service/web 3000:3000
```

然后就可以在浏览器中访问：http://localhost:3000

## 冗余备份

当前配置可维持2个pod，每个pod运行一个容器，进行冗余备份，如果其中一个被delete,那么k8s会立即启动一个新的pod：

```bash
$ kubectl delete pod web-6df8b8dbcb-t44z7
pod "web-6df8b8dbcb-t44z7" deleted from default namespace
```

在上面的命令执行过程中查看集群pod状态：

```bash
$ kubectl get pods -o wide
NAME                   READY   STATUS        RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
web-6df8b8dbcb-8t27b   1/1     Running       0          30s   10.244.1.3   test-worker    <none>           <none>
web-6df8b8dbcb-n789m   1/1     Running       0          23m   10.244.2.2   test-worker2   <none>           <none>
web-6df8b8dbcb-t44z7   1/1     Terminating   0          23m   10.244.1.2   test-worker    <none>           <none>

$ kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP           NODE           NOMINATED NODE   READINESS GATES
web-6df8b8dbcb-8t27b   1/1     Running   0          44s   10.244.1.3   test-worker    <none>           <none>
web-6df8b8dbcb-n789m   1/1     Running   0          23m   10.244.2.2   test-worker2   <none>           <none>
```

可以看到在`web-6df8b8dbcb-t44z7`进入终止过程的时候，同一个node中新的pod就已经被启动了。



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

## 冗余备份/扩缩

**扩缩是通过改变 Deployment 中的副本数量来实现的**

![](https://s41.ax1x.com/2026/02/14/pZLpDeK.png)

当前配置可维持2个pod，每个pod运行一个容器，进行冗余备份，如果其中一个被delete,那么k8s会立即启动一个新的pod：

```bash
$ kubectl delete pod web-6df8b8dbcb-t44z7
pod "web-6df8b8dbcb-t44z7" deleted from default namespace
```

这里实际上是， skaffold 自动创建了 2 个deployment里面的副本，deployment负责检查pod的状态，如果pod的容器终止了就立即重启:

```bash
$ kubectl get deployments
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    2/2     2            2           17h
```

在delete命令执行过程中查看集群pod状态：

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


## kind安装性能分析插件的方法

同样，因为**GFW**这个逆天玩意的存在，这个本应非常简单的过程变得极其繁琐🤮

执行下面的命令

```bash
# 手动从阿里云拉取镜像
docker pull registry.aliyuncs.com/google_containers/metrics-server:v0.8.0
# 打tag，应该改成的名称从resources下载的文件中找
docker tag registry.aliyuncs.com/google_containers/metrics-server:v0.8.0 registry.k8s.io/metrics-server/metrics-server:v0.8.0
# 由于 kind load 命令有 bug 会导致加载失败，需要用下面的命令手动把image加载到集群中的所有节点
# 参考：https://github.com/kubernetes-sigs/kind/issues/2402
docker save registry.k8s.io/metrics-server/metrics-server:v0.8.0 | docker exec -i test-control-plane ctr -n k8s.io images import -
docker save registry.k8s.io/metrics-server/metrics-server:v0.8.0 | docker exec -i test-worker ctr -n k8s.io images import -
docker save registry.k8s.io/metrics-server/metrics-server:v0.8.0 | docker exec -i test-worker2 ctr -n k8s.io images import -
# 验证镜像已经存在于所有节点
docker exec test-control-plane crictl images | grep metrics
docker exec test-worker crictl images | grep metrics  
docker exec test-worker2 crictl images | grep metrics
# 或者用下面的命令查看已经加载到集群的所有镜像
docker exec -it ltest-control-plane crictl images
```

然后参考[这里](https://gist.github.com/sanketsudake/a089e691286bf2189bfedf295222bd43),创建文件`kustomization.yaml`，内容如下：

```yaml
# kustomization.yaml
# kubectl apply -k .
resources:
- https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
patches:
- patch: |-
    - op: add
      path: /spec/template/spec/containers/0/args/-
      value: --kubelet-insecure-tls
  target:
    group: apps
    kind: Deployment
    name: metrics-server
    namespace: kube-system
    version: v1
```

最后执行下面的命令：

```bash
kubectl apply -k .
```

然后查看运行状态：

```bash
$ kubectl get pods -n kube-system -l k8s-app=metrics-server -w
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-576c8c997c-rjcdk   1/1     Running   0          59s

$ kubectl get pod,svc -n kube-system
NAME                                             READY   STATUS    RESTARTS        AGE
pod/coredns-66bc5c9577-57ljf                     1/1     Running   1 (3h21m ago)   19h
pod/coredns-66bc5c9577-q9jjg                     1/1     Running   1 (3h21m ago)   19h
pod/etcd-test-control-plane                      1/1     Running   0               3h21m
pod/kindnet-f9m7n                                1/1     Running   1 (3h21m ago)   19h
pod/kindnet-g26mq                                1/1     Running   1 (3h21m ago)   19h
pod/kindnet-l6k5b                                1/1     Running   1 (3h21m ago)   19h
pod/kube-apiserver-test-control-plane            1/1     Running   0               3h21m
pod/kube-controller-manager-test-control-plane   1/1     Running   1 (3h21m ago)   19h
pod/kube-proxy-5k8lk                             1/1     Running   1 (3h21m ago)   19h
pod/kube-proxy-84xp5                             1/1     Running   1 (3h21m ago)   19h
pod/kube-proxy-lzt2g                             1/1     Running   1 (3h21m ago)   19h
pod/kube-scheduler-test-control-plane            1/1     Running   1 (3h21m ago)   19h
pod/metrics-server-576c8c997c-rjcdk              1/1     Running   0               2m50s

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
service/kube-dns         ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   19h
service/metrics-server   ClusterIP   10.96.226.136   <none>        443/TCP                  50m
```

看到`Running`说明成功了。

最后终于可以使用性能分析工具了！

```bash
kubectl top pods
NAME                   CPU(cores)   MEMORY(bytes)
web-6df8b8dbcb-8t27b   0m           35Mi
web-6df8b8dbcb-n789m   1m           35Mi
```

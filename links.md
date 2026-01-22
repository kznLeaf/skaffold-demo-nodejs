要理解这个 Kubernetes 清单（Deployment/Service/ServiceAccount）都在做什么，可以对照官方文档去看每一块字段的定义和用途。下面我给出**官方参考文档入口**，方便逐个对照：

官方概念性说明（核心资源类型说明）

* ServiceAccount 是 Kubernetes 的服务身份，用于 Pod 与 Kubernetes API 的认证和授权，推荐在 Pod 需要访问集群 API 权限时使用，或者与 RBAC 结合控制权限。官方概念说明在 *Service Accounts – Kubernetes*。([Kubernetes][1])

如何为 Pod 配置 ServiceAccount

* 你 manifest 里有 `serviceAccountName: productcatalogservice`，这意味着 Pod 在运行时会使用同名的 ServiceAccount 对象。官方配置说明在 *Configure Service Accounts for Pods*。([Kubernetes][2])

Pod 和容器的安全上下文

* `securityContext` 在 Pod spec 里控制整个 Pod 级别的权限和安全设置（比如 runAsUser、fsGroup 等），容器级别也有自己的 securityContext 用于更细粒度的控制。官方示例和字段解释可以参考 *Configure a Security Context for a Pod or Container*。([Kubernetes][3])

健康检查（就绪探针 / 存活探针）

* 你配置了 `readinessProbe` 和 `livenessProbe` 使用 gRPC 方式，对应的官方说明在 *Configure Liveness, Readiness and Startup Probes*。这些探针用于 kubelet 判断容器是否已就绪接收流量以及是否存活。([Kubernetes][4])

Pod 资源请求和限制

* 你的 containers 里有 `resources.requests` 和 `resources.limits`，这些字段可以控制 Pod 的调度优先级和运行时资源上限。官方对资源请求和限制的解释可以在 Workloads 相关文档中看到（Deployment / Pod 规格 API 参考）。API 参考一般在 Kubernetes 官方 API 文档部分。

Service 定义

* Service 类型为 ClusterIP，表示集群内部可访问的服务。你设定了 selector 和端口映射，对 Service 如何工作 Kubernetes 有详细说明在 Service 概念页（可在 Kubernetes docs 中搜索 “Services”）。

另外一些高质量学习/参考链接（非官方但也是常用的）包括 Kubernetes 官方中文翻译站点的探针和安全上下文页面：

* 探针配置中文说明，用于理解 readiness 和 liveness 运行机制。([Kubernetes][5])
* 安全最佳实践检查清单，有助于理解为什么要 drop capabilities 或 runAsNonRoot。([Kubernetes][6])

这些文档片段覆盖了你 YAML 中主要字段的定义和用途。如果你要深入理解某个字段（比如 probes 的更详细参数或者 securityContext 内各子字段），可以直接在 Kubernetes 官方文档里搜索该字段名，会有 API 字段级别说明。

[1]: https://kubernetes.io/docs/concepts/security/service-accounts/?utm_source=chatgpt.com "Service Accounts - Kubernetes"
[2]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/?utm_source=chatgpt.com "Configure Service Accounts for Pods"
[3]: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/?utm_source=chatgpt.com "Configure a Security Context for a Pod or Container"
[4]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/?utm_source=chatgpt.com "Configure Liveness, Readiness and Startup Probes | Kubernetes"
[5]: https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/?utm_source=chatgpt.com "配置存活、就绪和启动探针 | Kubernetes"
[6]: https://kubernetes.io/docs/concepts/security/application-security-checklist/?utm_source=chatgpt.com "Application Security Checklist | Kubernetes"

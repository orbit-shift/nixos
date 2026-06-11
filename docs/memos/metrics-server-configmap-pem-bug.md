# metrics-server ConfigMap PEM 序列化 Bug

> 日期：2026-06-11
> 影响：metrics-server 无法工作，`kubectl top` 全部 Forbidden
> 环境：NixOS unstable, Kubernetes v1.36.1, metrics-server v0.8.1

## 现象

`kubectl top nodes` / `kubectl top pods -A` 全部报 Forbidden：

```
Error from server (Forbidden): nodes.metrics.k8s.io is forbidden:
User "front-proxy-client" cannot list resource "nodes" in API group "metrics.k8s.io" at the cluster scope
```

## 调试链条

### 1. Pod 层面

metrics-server pod 正常运行（1/1），APIService `v1beta1.metrics.k8s.io` Available=True，endpoints 正常。

### 2. metrics-server 日志

持续报错：

```
E0611 02:52:56 "Unhandled Error" err="kube-system/extension-apiserver-authentication failed with :
error loading CA bundle for \"client-ca::kube-system::extension-apiserver-authentication::requestheader-client-ca-file\":
data does not contain any valid RSA or ECDSA certificates"
```

### 3. 根因定位 — ConfigMap PEM 格式损坏

检查 `extension-apiserver-authentication` ConfigMap：

| 字段                          | 状态       | 详情                                            |
| ----------------------------- | ---------- | ----------------------------------------------- |
| `client-ca-file`              | ✅ 正确     | 21 行 PEM，换行正常（1258 bytes）                |
| `requestheader-client-ca-file` | ❌ 损坏    | 整个 PEM 挤成**一行**，换行全部变成空格（1279 bytes） |

对比磁盘源文件 `/var/lib/kubernetes/secrets/ca.pem`：**格式完全正确**（21 行，1257 bytes，`cat -A` 确认每行有 `$` 换行符）。

**结论**：kube-apiserver v1.36.1 启动时将 `--requestheader-client-ca-file` 指定的文件内容写入 ConfigMap 时，**PEM 换行被吞掉变成了空格**。同源的 `client-ca-file` 字段却正常，说明是 apiserver 处理 `requestheader-client-ca-file` 时的序列化 bug。

## 故障链条

```
apiserver v1.36 写 ConfigMap 时 PEM 换行丢失
  → metrics-server 加载 requestheader CA 失败
    → 无法验证 apiserver 代理请求的 X-Remote-User 请求头
      → 回退到 TLS 客户端证书 CN："front-proxy-client"
        → front-proxy-client 无 metrics.k8s.io RBAC 权限
          → Forbidden
```

## NixOS 配置现状

- `modules/k8s/k8s-common.nix` 中 `extraOpts` 已正确设置 `--requestheader-client-ca-file=/var/lib/kubernetes/secrets/ca.pem`
- NixOS easyCerts/pki 模块自动生成 `kube-apiserver-proxy-client.pem`（CN=`front-proxy-client`）并设置 `--proxy-client-cert-file` / `--proxy-client-key-file`
- `--requestheader-allowed-names`、`--requestheader-username-headers` 等参数需手动在 `extraOpts` 中设置（NixOS 模块不提供对应 option）

NixOS apiserver.nix 中的相关 option：

```nix
proxyClientCertFile = lib.mkOption { ... };  # pki 模块自动设为 kube-apiserver-proxy-client.pem
proxyClientKeyFile  = lib.mkOption { ... };  # pki 模块自动设为 kube-apiserver-proxy-client-key.pem
```

但**无** `requestheaderClientCaFile` / `requestheaderAllowedNames` 等 option，必须通过 `extraOpts` 手动传入。

## 修复方案

### A. 运行时修复（ConfigMap）

```sh
kubectl -n kube-system get configmap extension-apiserver-authentication -o json |
  jq --arg pem "$(kubectl -n kube-system get configmap extension-apiserver-authentication -o jsonpath='{.data.client-ca-file}')" \
    '.data["requestheader-client-ca-file"] = $pem' |
  kubectl apply -f -

kubectl -n kube-system rollout restart deployment/metrics-server
```

### B. metrics-server.yaml 增加 front-proxy-client RBAC

即使 ConfigMap 再次损坏，`front-proxy-client` 也能直接访问 metrics API（作为 fallback）。

已在 `modules/k8s/assets/metrics-server.yaml` 中添加：

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metrics-server:front-proxy-client
rules:
- apiGroups: ["metrics.k8s.io"]
  resources: [nodes, pods]
  verbs: [get, list, watch]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:front-proxy-client
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metrics-server:front-proxy-client
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: front-proxy-client
```

### C. systemd 服务自动修复 ConfigMap

已在 `modules/k8s/k8s-common.nix` 中添加 `fix-extension-apiserver-auth-certs` 服务：
- 仅在 master 节点运行（`builtins.elem "master" config.services.kubernetes.roles`）
- `after = [ "kube-apiserver.service" ]`，等待 apiserver 就绪后执行
- 检测 `requestheader-client-ca-file` 行数，若 < 3 行则用 `client-ca-file` 的内容修复

## 待确认

- `k8s-common.nix` systemd 服务脚本中引用了 `${pkgs.jq}`，需确认 nixpkgs 中 `jq` 可用（当前 `environment.systemPackages` 只显式列了 `yq-go`，但 `pkgs.jq` 作为标准包应可直接引用）
- 若后续升级 Kubernetes 版本，可观察此 bug 是否已在上游修复，若已修复则可移除该 systemd 服务

# ADR-012: K8s DNS 架构 — 分层解析 + 全局公共 DNS

**日期**: 2026-06-11
**状态**: 已采纳

### 问题

1. NixOS 宿主机 `/etc/resolv.conf` 指向 `127.0.0.1`（本地 CoreDNS stub resolver）
2. K8s pod 内 `127.0.0.1` 是容器 loopback（无 DNS 服务）
3. 集群内 CoreDNS 默认 `forward . /etc/resolv.conf`，转发到 pod 内的 `127.0.0.1` → 解析失败
4. CI workflow 的 report 模板尝试连接 `smtp.exmail.qq.com` 发信 → DNS 解析失败 → exit code 1

### 根因链路

```
Pod 查询外部域名（如 smtp.exmail.qq.com）
  → kube-dns ClusterIP (10.0.0.254)
  → 集群内 CoreDNS pod（dnsPolicy=Default，使用宿主机 /etc/resolv.conf）
  → Corefile: forward . /etc/resolv.conf
  → pod 内 /etc/resolv.conf 指向 127.0.0.1（容器 loopback，无 DNS 服务）
  → 解析失败
```

### 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **A. 改 CoreDNS dnsPolicy 为 None + dnsConfig** | 标准 K8s 做法 | CoreDNS deployment 有 `addonmanager.kubernetes.io/mode: Reconcile` label，会被 addon-manager 覆盖 |
| **B. 改 CoreDNS Corefile forward 目标** | 直接有效，不依赖 pod spec | 需要 patch configmap，非声明式 |
| **C. kubelet `--resolv-conf` 指向宿主机 CoreDNS** | 标准做法，pod 级生效 | 需要维护上游 DNS 文件 |
| **D. 分层解析 + 全局公共 DNS** | 单一配置源，地理位置解耦，条件适配 | 需要多处协调 |

### 决策

采用 **方案 D**，分层解析 + 全局公共 DNS 配置：

#### 1. 公共 DNS 作为全局配置

`flake.nix` 的 `commonArgs.publicDnsServers`（地理位置相关，中国大陆）：

```nix
commonArgs = {
  # ...
  publicDnsServers = [ "223.5.5.5" "119.29.29.29" "1.1.1.1" ];
};
```

#### 2. 宿主机 CoreDNS 引入即启用

`modules/services/coredns.nix` 设置 `networking.nameservers = [ "127.0.0.1" ]`：

```nix
config = {
  services.coredns = { ... };
  networking.nameservers = [ "127.0.0.1" ];  # 系统 DNS 指向本地 CoreDNS
};
```

#### 3. kubelet resolv.conf 动态决定

`modules/k8s/k8s-common.nix`：

```nix
environment.etc."kubelet-resolv.conf".text =
  if config.services.coredns.enable or false then ''
    nameserver ${cni0IP}
    options ndots:5
  '' else ''
    ${lib.concatMapStringsSep "\n" (s: "nameserver ${s}") publicDnsServers}
    options ndots:5
  '';
```

#### 4. 集群内 CoreDNS Corefile 动态决定

`modules/k8s/assets/patch-coredns.sh`：

```bash
FORWARD_TARGET="@FORWARD_TARGET@"
if [ "$FORWARD_TARGET" = "@CNI0_IP@" ]; then
  FORWARD_TARGET="$cni0IP"
fi
# Corefile: forward . $FORWARD_TARGET
```

`modules/k8s/k8s-addons.nix`：

```nix
forwardTarget =
  if config.services.coredns.enable or false
  then "@CNI0_IP@"  # 占位符，运行时替换为 cni0IP
  else publicDnsServersStr;  # 公共 DNS
```

### DNS 链路（有宿主机 CoreDNS）

```
Pod 查询外部域名
  → kube-dns ClusterIP (10.0.0.254)
  → 集群内 CoreDNS pod
  → Corefile: forward . <cni0IP>
  → 宿主机 CoreDNS（监听 0.0.0.0:53，通过 cni0 可达）
  → 宿主机 CoreDNS forward 到上游 DNS（阿里 223.5.5.5 等）
```

### 理由

1. **单一配置源** — 公共 DNS 在 `flake.nix` 定义一次，所有模块通过 `commonArgs` 获取
2. **引入即启用** — 宿主机 CoreDNS 模块自动设置系统 DNS 指向 `127.0.0.1`，无需额外开关
3. **条件适配** — 有/无宿主机 CoreDNS 两种场景自动适配，无需手动配置
4. **地理位置解耦** — 公共 DNS 列表与代码逻辑分离，换地区只改一处

### 后果

- `libs/nixos-builder.nix` 不再硬编码 `networking.nameservers`（由模块自己决定）
- `modules/k8s/k8s-addons.nix` 和 `modules/k8s/k8s-common.nix` 通过函数参数获取 `publicDnsServers`
- 新增 K8s 节点自动继承 DNS 配置，无需手动设置
- `modules/services/coredns.nix` 从 `modules/k8s/` 移至 `modules/services/`（与 K8s 无关）

### 相关文件

- `flake.nix` — `commonArgs.publicDnsServers`
- `modules/services/coredns.nix` — 宿主机 CoreDNS（引入即启用）
- `modules/k8s/k8s-common.nix` — kubelet `--resolv-conf`
- `modules/k8s/k8s-addons.nix` — CoreDNS patch 脚本
- `modules/k8s/assets/patch-coredns.sh` — Corefile patch 逻辑

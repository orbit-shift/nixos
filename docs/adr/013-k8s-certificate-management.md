# ADR-013: K8s 证书管理 — 权限策略 + kubeconfig 生成

**日期**: 2026-06-16
**状态**: 已采纳

### 问题

1. **证书权限问题**：NixOS kubernetes 模块硬编码私钥权限为 0600（-rw-------），即使组是 kubernetes，组成员也无法读取
2. **kubeconfig 分发**：用户需要将 kubeconfig 下载到本地和 CI 环境，但证书内联到 Nix 配置会进入 /nix/store/

### 根因分析

#### 证书权限

```
NixOS kubernetes pki 模块硬编码：
  privateKeyOptions = {
    owner = "kubernetes";
    group = "kubernetes";
    mode = "0600";  # 只有所有者有权限
  }
  → 组成员无法读取私钥
  → kubectl 报错：permission denied
```

#### kubeconfig 分发

```
方案 A：将证书内联到 Nix 配置
  → 证书进入 /nix/store/（只读，全局可见）
  → 私钥泄露风险
  → 违反安全最佳实践

方案 B：保持原始权限，手动复制
  → 每次证书更新都需要手动操作
  → 容易遗忘，导致 kubeconfig 过期
```

### 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **A. 永久开放证书权限（chmod 640）** | 简单直接 | 违反最小权限原则，永久开放 |
| **B. 将证书内联到 Nix 配置** | 声明式，自动分发 | 私钥进入 /nix/store/，泄露风险 |
| **C. 脚本自动生成 kubeconfig** | 一次性行为，用户可控 | 需要监控证书变化 |

### 决策

采用 **组合方案**：

#### 1. 保持原始证书权限（0600）

不修改 NixOS kubernetes 模块的权限设置，保持私钥权限为 0600。

**理由**：
- 符合最小权限原则
- 私钥是敏感数据，不应永久开放
- 用户决定自己管理密码/私钥，知晓风险
- 责任边界清晰：AI 不应过度保护

#### 2. 脚本自动生成 kubeconfig

`modules/k8s/assets/generate-kubeconfig.sh`：

```bash
#!/usr/bin/env bash
# 生成一次性 kubeconfig 文件
# 用法: sudo generate-kubeconfig.sh [输出路径]
# 默认输出: ~/.kube/config

set -euo pipefail

SECRETS_DIR=***
OUTPUT_PATH="${1:-$HOME/.kube/config}"
APISERVER="${2:-https://localhost:6443}"
CLUSTER_NAME="${3:-dx}"

# 读取证书和私钥
CA_CERT=$(sudo cat "$SECRETS_DIR/ca.pem")
CLIENT_CERT=$(sudo cat "$SECRETS_DIR/cluster-admin.pem")
CLIENT_KEY=$(sudo cat "$SECRETS_DIR/cluster-admin-key.pem")

# 生成 kubeconfig
cat > "$OUTPUT_PATH" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $(echo "$CA_CERT" | base64 -w 0)
    server: $APISERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: cluster-admin
  name: $CLUSTER_NAME
current-context: $CLUSTER_NAME
users:
- name: cluster-admin
  user:
    client-certificate-data: $(echo "$CLIENT_CERT" | base64 -w 0)
    client-key-data: $(echo "$CLIENT_KEY" | base64 -w 0)
EOF

chmod 600 "$OUTPUT_PATH"
```

`modules/k8s/k8s-common.nix`：

```nix
# 添加 kubernetes 用户组
users.groups.kubernetes = {};
users.groups.kubernetes.members = lib.attrNames (
  lib.filterAttrs (name: user: user.isNormalUser or false) config.users.users
);

# 添加 systemd 服务：生成 kubeconfig
systemd.services.generate-kubeconfig = {
  description = "Generate kubeconfig for current user";
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
  script = ''
    ${pkgs.bash}/bin/bash ${./assets/generate-kubeconfig.sh}
  '';
};

# 添加 systemd 路径监控：证书更新时自动触发
systemd.paths.generate-kubeconfig = {
  description = "Watch for certificate changes";
  wantedBy = [ "multi-user.target" ];
  pathConfig = {
    PathChanged = "/var/lib/kubernetes/secrets/cluster-admin.pem";
  };
};
```

**理由**：
- kubeconfig 是一次性行为，用户可以自己决定是否删除
- 证书更新时自动生成，无需手动操作
- 私钥不会进入 /nix/store/
- 责任边界清晰：用户决定自己管理密码/私钥

### 理由

1. **权限策略**：保持原始权限 0600，符合最小权限原则，私钥不应永久开放
2. **kubeconfig 生成**：脚本自动生成是一次性行为，用户可以自己决定是否删除，私钥不会进入 /nix/store/
3. **责任边界**：用户决定自己管理密码/私钥，知晓风险，AI 不应过度保护

### 后果

- 证书权限保持 0600，符合安全最佳实践
- kubeconfig 在证书更新时自动生成到 `~/.kube/config`
- 用户可以手动运行 `sudo generate-kubeconfig.sh` 生成 kubeconfig
- 私钥不会进入 /nix/store/，降低泄露风险

### 相关文件

- `modules/k8s/assets/generate-kubeconfig.sh` — kubeconfig 生成脚本
- `modules/k8s/k8s-common.nix` — kubernetes 用户组 + systemd 服务/路径监控

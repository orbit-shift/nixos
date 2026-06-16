#!/usr/bin/env bash
# 生成一次性 kubeconfig 文件
# 用法: sudo generate-kubeconfig.sh [输出路径] [集群名称] [API Server地址]
# 默认值:
#   输出路径: ~/.kube/config
#   集群名称: kubernetes
#   API Server: https://172.178.5.123:6443 (从当前节点读取)

set -euo pipefail

SECRETS_DIR=*** 设置默认值
OUTPUT_PATH="${1:-$HOME/.kube/config}"
CLUSTER_NAME="${2:-kubernetes}"

# 从 kubernetes 配置中读取 API Server 地址，如果未提供第三个参数
if [ $# -ge 3 ]; then
    APISERVER="$3"
else
    # 尝试从运行中的 kube-apiserver 读取，或使用默认值
    APISERVER="https://localhost:6443"
fi

# 检查证书文件是否存在
if [ ! -f "$SECRETS_DIR/cluster-admin.pem" ] || [ ! -f "$SECRETS_DIR/cluster-admin-key.pem" ]; then
    echo "错误: 证书文件不存在，请确保 Kubernetes 已正确初始化"
    exit 1
fi

# 创建输出目录
mkdir -p "$(dirname "$OUTPUT_PATH")"

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

# 设置权限（仅所有者可读写）
chmod 600 "$OUTPUT_PATH"

echo "✓ kubeconfig 已生成: $OUTPUT_PATH"
echo "  集群名称: $CLUSTER_NAME"
echo "  API Server: $APISERVER"
echo "⚠ 警告: 此文件包含私钥，请妥善保管"
echo "  - 不要提交到 git"
echo "  - 不要上传到公共位置"
echo "  - 使用后可手动删除: rm $OUTPUT_PATH"

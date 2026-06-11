#!/usr/bin/env bash
# Patch CoreDNS env to use cni0 bridge IP as KUBERNETES_SERVICE_HOST.
# Variables @KUBECTL@ and @KUBECONFIG@ are injected by Nix replaceStrings.
#
# NOTE: This script assumes cni0 interface already exists.
# The k8s-flannel-apply.service is responsible for ensuring cni0 is ready
# before this service runs (via systemd requires dependency).

# Get cni0 interface IP (API Server reachable via this on single-node)
apiServerIP=$(ip -4 addr show cni0 2>/dev/null | grep -oP 'inet \K[\d.]+')
if [ -z "$apiServerIP" ]; then
  echo "[coredns-patch] ERROR: Could not detect cni0 IP"
  exit 1
fi
echo "[coredns-patch] Using API server IP: $apiServerIP"

@KUBECTL@ --kubeconfig=@KUBECONFIG@ patch deployment coredns -n kube-system \
  -p '{"spec":{"template":{"spec":{"$setElementOrder/containers":[{"name":"coredns"}],"containers":[{"name":"coredns","env":[{"name":"KUBERNETES_SERVICE_HOST","value":"'$apiServerIP'"},{"name":"KUBERNETES_SERVICE_PORT","value":"6443"}]}]}}}}'

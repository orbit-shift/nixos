{ pkgs, lib, ... }: {
  # CRI-O 容器运行时（k8s 推荐运行时）
  virtualisation.cri-o = {
    enable = true;
    settings = {
      crio = {
        image.default_transport = "docker://";
        runtime.runtimes = {
          crun = {
            path = "${pkgs.crun}/bin/crun";
            allowed_annotations = [ "io.containerd.runc.v2.runc.options" ];
          };
        };
      };
    };
  };

  # k8s 所需内核模块（参考 Ansible kubecommon: overlay, br_netfilter）
  boot.kernelModules = [ "overlay" "br_netfilter" ];

  # k8s 所需系统参数（参考 Ansible 99-kubernetes-cri.conf.j2）
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
    "fs.inotify.max_user_instances" = 8192;
  };

  # 系统 ulimits 配置（参考 Ansible 30-k8s-ulimits.conf.j2）
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "core"; value = "infinity"; }
    { domain = "*"; type = "hard"; item = "core"; value = "infinity"; }
    { domain = "*"; type = "soft"; item = "nofile"; value = 100000; }
    { domain = "*"; type = "hard"; item = "nofile"; value = 100000; }
    { domain = "*"; type = "soft"; item = "nproc"; value = 100000; }
    { domain = "*"; type = "hard"; item = "nproc"; value = 100000; }
  ];

  # Kubernetes 组件配置（参考 Ansible kubeadm/kubecommon/kubecommonpost）
  services.kubernetes.kubelet = {
    enable = true;
    # 指定 CRI-O socket 路径与超时（参考 0-crio.conf）
    extraOptions = [
      "--container-runtime-endpoint=unix:///run/crio/crio.sock"
      "--runtime-request-timeout=10m"
      # 最大 Pod 数量（参考 kubecommonpost: maxPods: 500）
      "--max-pods=500"
    ];
  };

  # kube-apiserver NodePort 范围扩展（参考 Ansible kubeadm.conf: 1-32767）
  services.kubernetes.apiserver.extraOptions = [
    "--service-node-port-range=1-32767"
  ];

  environment.systemPackages = with pkgs; [
    kubectl
    kubeadm
    kubernetes-helm
  ];

  # k8s 所需端口（参考 Ansible firewall 配置）
  networking.firewall.allowedTCPPorts = [
    80 443      # Ingress/Service
    6443        # kube-apiserver
    2379 2380   # etcd
    10250       # kubelet
  ];
  # NodePort 范围（1-32767，通过 iptables 直接配置）
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp --dport 1:32767 -j nixos-fw-accept
  '';

  # 关闭 swap（k8s 要求）
  swapDevices = lib.mkForce [];
}

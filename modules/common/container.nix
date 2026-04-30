{ pkgs, lib, ... }: {
  # ── Podman ───────────────────────────────────────────────
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;   # `docker` -> `podman` alias
    defaultNetwork.settings.dns_enabled = true;
  };

  # ── Containerd ───────────────────────────────────────────
  virtualisation.containerd = {
    enable = false;          # 默认禁用
    settings = {
      plugins."io.containerd.grpc.v1.cri" = {
        sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.9";
      };
    };
  };

  # ── Container Registries ─────────────────────────────────
  environment.etc."containers/registries.conf".text = lib.mkForce ''
    unqualified-search-registries = ["docker.io"]

    [[registry]]
    insecure = true
    location = "registry.s"

    [[registry]]
    insecure = true
    location = "registry.d"

    [[registry]]
    insecure = true
    location = "172.178.5.123:5000"

    [[registry]]
    insecure = true
    location = "localhost:5000"

    [[registry]]
    prefix = "docker.io"
    location = "docker.lizzie.fun"

    [[registry]]
    prefix = "ghcr.io"
    location = "ghcr.lizzie.fun"
  '';


  # Podman storage 配置（路径放在 /root 下）
  environment.etc."containers/storage.conf".text = lib.mkForce ''
    [storage]
    driver = "overlay"
    runroot = "/root/.local/share/containers/storage/runroot"
    graphroot = "/root/.local/share/containers/storage"
  '';
  # ── Container Image Tools ───────────────────────────────
  environment.systemPackages = with pkgs; [
    buildah
    skopeo
  ];
}

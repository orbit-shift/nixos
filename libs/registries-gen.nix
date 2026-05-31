# 容器镜像仓库配置模块
# 根据运行时类型生成对应的镜像仓库配置：
#   - containerd: /etc/containerd/certs.d/*/hosts.toml
#   - crio/podman: /etc/containers/registries.conf
#
# 用法：import ./registries-gen.nix { inherit lib; runtime = "containerd"; registriesData = import ./registries.nix; }
{ lib, runtime, registriesData }:

let
  # Containerd hosts.toml（代理仓库）
  containerdTomls = lib.mapAttrs' (prefix: location: {
    name = "containerd/certs.d/${prefix}/hosts.toml";
    value = {
      text = ''
        server = "https://${prefix}"
        [host."https://${location}"]
          capabilities = ["pull", "resolve"]
      '';
    };
  }) registriesData.proxyRegistries //
  lib.listToAttrs (map (loc: {
    name = "containerd/certs.d/${loc}/hosts.toml";
    value = {
      text = ''
        server = "http://${loc}"
        [host."http://${loc}"]
          capabilities = ["pull", "resolve"]
      '';
    };
  }) registriesData.insecureRegistries);

  # Podman/CRI-O registries.conf TOML
  registriesConf = ''
    unqualified-search-registries = ["docker.io"]

    # 代理镜像配置
  '' + lib.concatStringsSep "\n" (lib.mapAttrsToList (prefix: location: ''
    [[registry]]
    prefix = "${prefix}"
    location = "${location}"
  '') registriesData.proxyRegistries) + "\n\n" +
  lib.concatStringsSep "\n" (map (loc: ''
    [[registry]]
    insecure = true
    location = "${loc}"
  '') registriesData.insecureRegistries) + "\n";

in {
  environment.etc =
    (if runtime == "containerd" then containerdTomls else {}) //
    # 始终生成 registries.conf（Podman/nerdctl 等工具需要此文件）
    { "containers/registries.conf".text = lib.mkForce registriesConf; };
}

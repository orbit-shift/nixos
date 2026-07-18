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

  # Podman/CRI-O — podman 6 重写了配置解析，改用 registries.conf.d/ drop-in 目录
  registriesDropin =
    # 默认检索注册表
    { "containers/registries.conf.d/01-unqualified-search.conf".text = ''
        unqualified-search-registries = ["docker.io"]
      '';
    } //
    # 代理镜像配置（每个前缀一个文件）
    (lib.mapAttrs' (prefix: location: {
      name = "containers/registries.conf.d/50-proxy-${lib.replaceStrings ["." ":"] ["-" "-"] prefix}.conf";
      value.text = ''
        [[registry]]
        prefix = "${prefix}"
        location = "${location}"
      '';
    }) registriesData.proxyRegistries) //
    # 不安全注册表（每个注册表一个文件，prefix 匹配 + location 强制 :80 走 HTTP）
    (lib.listToAttrs (map (loc:
      let target = if lib.hasInfix ":" loc then loc else "${loc}:80"; in {
      name = "containers/registries.conf.d/99-insecure-${lib.replaceStrings ["." ":"] ["-" "-"] loc}.conf";
      value.text = ''
        [[registry]]
        prefix = "${loc}"
        location = "${target}"
        insecure = true
      '';
    }) registriesData.insecureRegistries));

in {
  environment.etc =
    (if runtime == "containerd" then containerdTomls else {}) //
    registriesDropin;
}

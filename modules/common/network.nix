{ pkgs, ... }: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    # WireGuard 通过 systemd-networkd 或 wg-quick 管理
    # 配置文件放 /etc/wireguard/，通过 secrets 注入
  };

  # WireGuard 接口（密钥文件用 sops-nix 或 agenix 管理）
  networking.wg-quick.interfaces = {
    wg0 = {
      configFile = "/etc/wireguard/wg0.conf";
      autostart = true;
    };
    wg3 = {
      configFile = "/etc/wireguard/wg3.conf";
      autostart = true;
    };
  };

  # 网络诊断与管理工具
  environment.systemPackages = with pkgs; [
    openbsd-netcat
    resolvconf
    wireguard-tools
  ];
}
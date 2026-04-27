{ pkgs, ... }: {
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    };

  # 网络诊断与管理工具
  environment.systemPackages = with pkgs; [
    openbsd-netcat
    resolvconf
  ];
}
{ pkgs, ... }: {
  users.users.master = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = [
      "wheel"
      "lp"
      "wireshark"
      "podman"
    ];
    # 把你的 SSH 公钥放这里
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... master@workstation"
    ];
  };

  # wireshark 组 + dumpcap capability
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  # lp 组（打印机）
  services.printing.enable = true;
}

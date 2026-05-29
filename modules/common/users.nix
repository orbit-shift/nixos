{ pkgs, user, ... }: {
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.bash;
    # mkpasswd -m yescrypt "qwer"
    hashedPassword = "$y$j9T$hSonE3YWKoH$y$j9T$K6.dofzliwDGxsZ1jgRrf.$BeExKPCaux5Irn16Jt.MBPMjIghzaEPls1D95f3/VL/";
    extraGroups = [
      "wheel"
      "lp"
      "podman"
    ];
    # SSH pubkey
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK2Q46WeaBZ9aBkS3TF2n9laj1spUkpux/zObmliHUOI"
    ];
  };

  # lp 组（打印机）
  services.printing.enable = true;
}

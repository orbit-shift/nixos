{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    telegram-desktop
    wechat # nix-community 维护的 wechat-uos
    feishu
  ];

  nixpkgs.config.allowUnfree = true;
}

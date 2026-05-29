{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    telegram-desktop
    # WeChat（nix-community 维护的 wechat-uos）
    wechat
    feishu
  ];

  nixpkgs.config.allowUnfree = true;
}

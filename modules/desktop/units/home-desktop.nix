# 桌面环境专属 Home Manager 配置
# 由 desktop/{base,full,mini}.nix 导入
{ config, pkgs, lib, user, ... }: {
  home-manager.users.${user} = {
    imports = [
      ./home-terminals.nix
      ./home-xdg.nix
    ];
  };
}

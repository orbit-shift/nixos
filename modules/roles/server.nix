# 服务器角色基座
{ pkgs, user, ... }: {
  imports = [
    ../system/core.nix
    ../system/units/vm.nix
    ../dev/server.nix
  ];

  home-manager.users.${user} = {
    imports = [ ../home/headless.nix ];
  };
}

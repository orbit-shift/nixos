# 便携式维护系统域
{ inputs, user, lib, dataDir, ... }:

{
  portable = {
    imports = [
      inputs.disko.nixosModules.disko
      ./existing-disk.nix
      ./hardware-configuration.nix
      ../../modules/roles/portable.nix
    ];
  };
}

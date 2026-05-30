# Bob 的硬件配置
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot.initrd.availableKernelModules = [ "ahci" "sd_mod" ];
  fileSystems."/" = { device = "/dev/sda2"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/sda1"; fsType = "vfat"; };
}

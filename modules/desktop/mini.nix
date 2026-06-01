# 最小桌面预设：QEMU 虚拟机
# 仅包含基础桌面框架，不含 Hyprland 和应用
{ pkgs, ... }: {
  imports = [
    ./units/cosmic.nix
    ./units/greetd.nix
    ./units/input-method.nix
    ./units/fonts.nix
    ./units/accessibility.nix
  ];
}

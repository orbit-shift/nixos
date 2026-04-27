{ config, pkgs, ... }: {
  # Nushell 启用
  # 硬核用户自行管理 config.nu / env.nu / 补全 / prompt 等
  programs.nushell.enable = true;

  # 链接用户自有的 nu/ 配置库到 ~/.config/nushell
  # 假设 flake 仓库 clone 在 ~/nixos/
  home.file.".config/nushell".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/nu";
}
{ pkgs, lib, config, dataDir, user, ... }:

let
  localPkg = import ../../lib/local-pkg.nix { inherit pkgs user; };
in {

  # wireshark 组 + dumpcap capability
  # 自动将所有 normal users 加入 wireshark 组
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  users.groups.wireshark.members = lib.attrNames (
    lib.filterAttrs (name: user: user.isNormalUser or false) config.users.users
  );

  environment.systemPackages = with pkgs; [
    # Shell & 终端
    ghostty
    alacritty       # 备用终端

    # 编辑器
    # neovim
    # neovide         # neovim GUI 前端
    zed-editor

    # 媒体播放
    nomacs
    qimgv
    mpv
    ffmpeg

    # 浏览器
    firefox
    chromium
    qutebrowser
    # Vivaldi 缩放修复：本地 .deb + 强制 1:1 像素渲染
    # (localPkg { pkg = pkgs.vivaldi; filename = "vivaldi-stable_8.0.4033.34-1_amd64.deb"; })
    ((localPkg { pkg = pkgs.vivaldi; filename = "vivaldi-stable_8.0.4033.34-1_amd64.deb"; }).overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram "$out/bin/vivaldi" \
          --add-flags "--force-device-scale-factor=1" \
          --add-flags "--enable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--ozone-platform-hint=auto"
      '';
    }))

    # 文件 & 办公
    freefilesync
    gparted

    # 截图
    flameshot

    # 桌面通知
    libnotify
  ];

  # Chromium 内核浏览器（Vivaldi/Chromium）HiDPI 修复：
  # 强制 Wayland 原生渲染 + 固定缩放因子 1.0，忽略 compositor 报告的缩放
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --force-device-scale-factor=1";

  # programs.gparted.enable removed in newer nixpkgs; gparted still in environment.systemPackages

  # 移除工作站默认包集（含 nano 等），仅安装显式声明的包
  environment.defaultPackages = [];

  nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (pkg.pname or "") [
        "freefilesync"
        "vivaldi"
      ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}

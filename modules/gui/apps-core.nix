{ pkgs, lib, config, dataDir, user, ... }:

let
  localPkg = import ../../lib/local-pkg.nix { inherit pkgs user; };

  # ── Vivaldi：Wayland IME 修复 ──────────────────────────
  # symlinkJoin + wrapProgram 会因符号链接导致 "not an executable file" 错误
  # 改用 writeShellScriptBin 创建包装脚本
  vivaldiWrapped = pkgs.writeShellScriptBin "vivaldi" ''
    exec ${
      localPkg { pkg = pkgs.vivaldi; filename = "vivaldi-stable_8.0.4033.34-1_amd64.deb"; }
    }/bin/vivaldi \
      --enable-wayland-ime \
      --ozone-platform-hint=auto \
      "$@"
  '';

  # ── Zed Editor：XWayland 兼容层启动，杜绝失焦闪退 ─────
  zedWrapped = pkgs.writeShellScriptBin "zed" ''
    export WAYLAND_DISPLAY=""
    export XMODIFIERS="@im=fcitx"
    export GTK_IM_MODULE="fcitx"
    exec ${pkgs.zed-editor}/bin/zed "$@"
  '';
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
    zedWrapped        # XWayland 包装版（带 fcitx 兼容层）

    # 媒体播放
    nomacs
    qimgv
    mpv
    ffmpeg

    # 浏览器
    firefox
    chromium
    qutebrowser
    vivaldiWrapped    # Wayland IME 包装版

    # 文件 & 办公
    freefilesync
    gparted

    # 截图
    flameshot

    # 桌面通知
    libnotify
  ];

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

# 浏览器配置：Vivaldi + Chromium
# --disable-features=WaylandPerSurfaceScale 切断 Chromium 与 compositor 的重复缩放计算
# --enable-wayland-ime 开启 Wayland 原生输入法文本协议
{ pkgs, lib, user, ... }:

let
  localPkg = import ../../../libs/local-pkg.nix { inherit pkgs user; };
  # 本地 .deb 路径：纯评估模式（nix flake check）下不可用，回退到 nixpkgs 版本
  vivaldiPkg =
    let
      canAccess = builtins.tryEval (builtins.pathExists "/home/${user}/pub/Application/Linux/vivaldi-stable_8.0.4033.35-1_amd64.deb");
    in
      if canAccess.success && canAccess.value
      then localPkg { pkg = pkgs.vivaldi; filename = "vivaldi-stable_8.0.4033.35-1_amd64.deb"; }
      else pkgs.vivaldi;
in {
  # ── Vivaldi Overlay：修复 COSMIC 200% 缩放下界面放大 ──
  nixpkgs.overlays = [
    (final: prev: {
      vivaldi = prev.vivaldi.override {
        commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --disable-features=WaylandPerSurfaceScale --force-device-scale-factor=1 --enable-wayland-ime";
      };
    })
  ];

  # ── 浏览器包 ────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vivaldiPkg
  ];

  # ── Chromium 内核全局配置 ───────────────────────────
  # 强制 Wayland 原生渲染 + 固定 1:1 像素缩放
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --force-device-scale-factor=1";

  # ── 允许非自由包 ────────────────────────────────────
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or "") [
      "vivaldi"
    ];
}

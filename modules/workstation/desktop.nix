{ pkgs, lib, dataDir, ... }: {
  # ── COSMIC Desktop Environment ─────────────────────────
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # ── Pipewire Audio ─────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Input Method: fcitx5 + Rime + 五笔 ─────────────────
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-qt
      (fcitx5-rime.override {
        rimeDataPkgs = [ pkgs.rime-data "${dataDir}/rime-wubi" ];
      })
      fcitx5-chinese-addons
      rime-wubi
    ];
  };

  # ── XDG Desktop Portal (COSMIC backend) ────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
  };

  # ── 字体配置 ───────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      lilex
      (nerdfonts.override { fonts = [ "Lilex" "JetBrainsMono" ]; })
      wqy-zenhei
    ];
    fontconfig.defaultFonts = {
      monospace = [ "Lilex" "Noto Sans Mono CJK SC" ];
      sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    };
  };

  # COSMIC DE 已内置 HiDPI 设置界面，无需像 SDDM/Hyprland 那样手动注入 DPI 配置
  # 若需针对 GTK/Qt 应用强制全局缩放，可取消下方注释：
  # environment.sessionVariables = {
  #   GDK_SCALE = "2";
  #   QT_SCALE_FACTOR = "2";
  # };

  # ── Wayland 剪贴板（仅桌面需要） ──────────────────────────
  environment.systemPackages = with pkgs; [ wl-clipboard ];
}
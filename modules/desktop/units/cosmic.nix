{ pkgs, lib, dataDir, ... }: {
  # ── COSMIC Desktop Environment ─────────────────────────
  services.desktopManager.cosmic.enable = true;

  # ── SDDM 登录管理器（EndeavourOS 风格：模糊背景） ─────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-sugar-dark";
    settings.Theme = {
      # EndeavourOS 风格：模糊背景
      # 替换为你的桌面壁纸路径，例如：
      # Background = "/home/master/Pictures/wallpaper.jpg";
      blur = true;
    };
  };

  # SDDM 主题包
  services.displayManager.sddm.extraPackages = with pkgs; [
    sddm-sugar-dark
  ];

  # ── Pipewire Audio ─────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── XDG Desktop Portal (COSMIC backend) ────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
  };
}

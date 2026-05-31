{ pkgs, lib, ... }: {
  # ── Input Method: fcitx5 + Rime ──────────────────────
  config = {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = [
          pkgs.fcitx5-gtk
          pkgs.fcitx5-rime
          pkgs.qt6Packages.fcitx5-configtool
          pkgs.qt6Packages.fcitx5-chinese-addons
        ];
      };
    };

    # ── Fcitx5 休眠唤醒后自动重启 ────────────────────────
    # COSMIC 锁屏 SIGKILL 输入法 Applet 导致 Wayland IM 断联。
    # 系统级 resume hook 通过 runuser 触发用户级 fcitx5 重启。
    powerManagement.resumeCommands = ''
      ${pkgs.systemd}/bin/runuser -u master -- ${pkgs.procps}/bin/pkill -f fcitx5 || true
      sleep 1
      ${pkgs.systemd}/bin/runuser -u master -- ${pkgs.fcitx5}/bin/fcitx5 -d || true
    '';
  };
}

{ pkgs, lib, dataDir, ... }: {
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

  # 设置环境变量，让 GTK/Qt/Wayland 应用使用 fcitx5
  environment.sessionVariables = {
    INPUT_METHOD = "fcitx5";
    GTK_IM_MODULE = "fcitx5";
    QT_IM_MODULE = "fcitx5";
    XMODIFIERS = "@im=fcitx5";
  };
}
{ pkgs, lib, dataDir, config, ... }:

let
  cfg = config.services.inputMethod;

  # 五笔数据派生（仅当启用时才会被求值）
  wubiPkg = pkgs.stdenvNoCC.mkDerivation {
    name = "fcitx5-rime-data";
    src = "${dataDir}/rime-wubi";
    installPhase = ''
      mkdir -p $out/share/rime-data
      cp -r ./* $out/share/rime-data/
    '';
  };

  # Rime 数据：雾凇拼音（包含小鹤双拼 rime_ice_double_pinyin_flypy）
  rimeDataPkgs = [ pkgs.rime-ice ]
    ++ lib.optionals cfg.fcitx5.rimeData.rimeWubi.enable [ wubiPkg ];
in {
  options.services.inputMethod.fcitx5.rimeData.rimeWubi = {
    enable = lib.mkEnableOption "Rime 五笔输入数据（需 ${dataDir}/rime-wubi 目录存在）";
  };

  # ── Input Method: fcitx5 + Rime + 五笔 ─────────────────
  config = {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-gtk
        (fcitx5-rime.override { inherit rimeDataPkgs; })
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };
}

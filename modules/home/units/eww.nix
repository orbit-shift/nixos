{ config, lib, pkgs, ... }:

let
  ewwDir = ../assets/eww;
in
{
  programs.eww = {
    enable = true;
    yuckConfig = builtins.readFile "${ewwDir}/eww.yuck";
    scssConfig = builtins.readFile "${ewwDir}/eww.scss";
  };

  # 额外文件（widgets 和 scripts）通过 xdg.configFile 注入
  xdg.configFile."eww/widgets" = {
    source = "${ewwDir}/widgets";
    recursive = true;
  };

  xdg.configFile."eww/scripts" = {
    source = "${ewwDir}/scripts";
    recursive = true;
  };
}

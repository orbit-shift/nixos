{ pkgs, lib, user, ... }:

let
  userWallpaperDir = "/home/${user}/Pictures/wallpaper";
  targetDir = "/var/lib/greetd-wallpapers";
  targetFile = "${targetDir}/wallpaper.jpg";
in
{
  # 1. 关闭 NixOS 默认的 regreet 管理，完全接管配置
  programs.regreet.enable = false;

  # 2. 部署自定义配置文件到 /etc/greetd
  environment.etc."greetd/regreet.toml".source = ../assets/greetd/config.toml;
  environment.etc."greetd/style.css".source = ../assets/greetd/style.css;

  # 3. Greetd 设置
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet --config /etc/greetd/regreet.toml --style /etc/greetd/style.css";
        user = "greeter";
      };
    };
  };

  # 4. 禁用 Keyring
  services.gnome.gnome-keyring.enable = false;

  # 5. 壁纸服务
  systemd.services.greetd-wallpaper-rotator = {
    description = "Randomly pick a login wallpaper";
    wantedBy = [ "greetd.service" ];
    before = [ "greetd.service" ];
    script = ''
      mkdir -p ${targetDir}
      img=$(${pkgs.fd}/bin/fd . ${userWallpaperDir} -d 1 -t f -e jpg -e jpeg -e png | shuf -n 1)
      if [ -n "$img" ]; then
        ${pkgs.imagemagick}/bin/magick convert "$img" -resize "1920x1080^" -gravity center -extent 1920x1080 jpg:${targetFile}
      else
        ${pkgs.imagemagick}/bin/magick convert -size 1920x1080 xc:"#1e1e28" ${targetFile}
      fi
      chmod 644 ${targetFile}
    '';
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
  };

  systemd.tmpfiles.rules = [ "d ${targetDir} 0755 root root -" ];
}

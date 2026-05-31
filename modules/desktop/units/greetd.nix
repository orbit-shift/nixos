{ pkgs, lib, user, ... }:

let
  userWallpaperDir = "/home/${user}/Pictures/wallpaper";
  targetDir = "/var/lib/greetd-wallpapers";
  targetFile = "${targetDir}/wallpaper.jpg";
in
{
  # 1. 关闭 regreet
  # programs.regreet.enable = false; # 这一行去掉，改为下面配置 enable = true

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.cage}/bin/cage -s -- ${pkgs.regreet}/bin/regreet";
        user = "greeter";
      };
    };
  };

  # 2. ReGreet 配置：背景 + 透明登录框
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = targetFile;
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;
      appearance = {
        greeting_msg = ""; # 不要欢迎语，更简洁
        show_clock = false; # 不要时钟
      };
    };
    # 3. 极简透明 CSS
    extraCss = ''
      /* 让所有容器和卡片背景透明 */
      window, .background, box, grid, .card, frame {
        background: transparent !important;
        background-color: transparent !important;
        border: none !important;
        box-shadow: none !important;
      }
      /* 输入框样式 */
      entry {
        background: rgba(255, 255, 255, 0.15) !important;
        border-radius: 8px;
        border: none;
        padding: 10px;
      }
      entry:focus {
        background: rgba(255, 255, 255, 0.25) !important;
      }
      label {
        color: #ffffff;
        text-shadow: 0 2px 4px rgba(0,0,0,0.5);
      }
    '';
  };

  # 4. 禁用 Keyring 避免弹窗
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

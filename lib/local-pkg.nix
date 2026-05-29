# 用本地文件替换包的 src 属性
# 支持 deb / rpm / tarball / AppImage 等任意格式
#
# 参数：
#   pkg      - 要覆盖的包（如 pkgs.vivaldi）
#   filename - 文件名
#   baseDir  - 本地文件所在目录，默认 /home/${user}/pub/Application/Linux
#
# 示例：
#   localPkg pkgs.vivaldi "vivaldi-stable_8.0.4033.34-1_amd64.deb"
#   localPkg pkgs.wechat "wechat-xxx.AppImage" "/home/user/Downloads"
{ pkgs, user }:

let
  defaultBaseDir = "/home/${user}/pub/Application/Linux";
in
{ pkg, filename, baseDir ? defaultBaseDir }:
pkg.overrideAttrs (old: {
  src = builtins.path {
    path = "${baseDir}/${filename}";
    name = filename;
  };
})

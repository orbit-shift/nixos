{ inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko

    # ── 通用基础模块 (与 ISO 保持一致，确保工具链完整) ──
    ../../modules/common/sys.nix
    ../../modules/common/base.nix
    ../../modules/common/users.nix
    ../../modules/common/network.nix
    ../../modules/common/container.nix
    ../../modules/common/extra.nix
  ];

  # ── 通用硬件支持 ──────────────────────────────────
  # 启用非自由固件与所有可能的固件，最大化对不同主板、WiFi、GPU 的兼容性
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # 使用最新内核以获得更好的硬件驱动支持
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── 文件系统支持 ──────────────────────────────────
  # 安装盘需能读写目标机器的各类分区
  boot.supportedFilesystems = [ "ntfs" "exfat" "ext4" "btrfs" "xfs" "vfat" ];

  # ── 网络与存储管理 ────────────────────────────────
  # NetworkManager 提供通用的网络配置能力
  networking.networkmanager.enable = true;

  # udisks2 用于自动挂载可移动设备（方便访问目标硬盘或 U 盘数据）
  services.udisks2.enable = true;

  # ── 性能与体验 ───────────────────────────────────
  # 启用 zram 交换，提升低内存环境下的响应速度
  zramSwap.enable = true;

  # 快速启动，不等待用户选择
  boot.loader.timeout = 5;

  # 自动登录 master 用户，启动即用
  services.getty.autologinUser = "master";


}
{ config, pkgs, lib, nushellSrc, nushellGitUrl, ... }:

let
  cfg = config.programs.nushell;
  nushellDir = "${config.home.homeDirectory}/Configuration/nushell";
  nushellInput = nushellSrc;
in
{
  options.programs.nushell.developMode = lib.mkEnableOption
    "Use symlink + git clone for nushell config (for development)";

  config = lib.mkMerge [
    # Enable bash and auto-launch nushell (safe fallback)
    {
      programs.bash.enable = true;
      programs.bash.bashrcExtra = ''
        # Auto-launch nushell for interactive shells
        # Without 'exec' so that if nu crashes, we fallback to bash
        if [[ $- == *i* && -z "$NU_SHELL" ]] && command -v nu >/dev/null 2>&1; then
          export NU_SHELL=1
          nu --login
          # 退出码 0 = 用户正常输入 exit → 自动退出 bash（只需一次 exit）
          # 退出码 ≠0 = nu 崩溃（配置不兼容） → 留在 bash 里修复
          [ $? -eq 0 ] && exit
        fi
      '';
    }
    # 始终启用 nushell + 插件 (polars / query web)
    # 注：插件放入 home.packages 而非 programs.nushell.plugins，避免与整目录 symlink 冲突
    {
    #   xdg.enable = true;
      programs.nushell.enable = true;
      programs.nushell.plugins = [ pkgs.nushellPlugins.polars pkgs.nushellPlugins.query ];
    }

    # 工作站开发模式：符号链接 + 自动克隆
    (lib.mkIf cfg.developMode {
      # 整目录符号链接
      home.file.".config/nushell" = {
        source = config.lib.file.mkOutOfStoreSymlink nushellDir;
        force = true;  # Overwrite if existing file/directory conflicts
      };

      # 自动克隆仓库（如果尚未存在）
      home.activation.cloneNushellConfig = ''
        if [ ! -d "${nushellDir}/.git" ]; then
          $DRY_RUN_CMD git clone ${nushellGitUrl} "${nushellDir}"
        fi
      '';
    })

    # 服务器/只读模式：通过 flake input 部署
    (lib.mkIf (!cfg.developMode) {
      # 整目录符号链接（避免逐个展开文件触发路径检查）
      home.file.".config/nushell" = {
        source = config.lib.file.mkOutOfStoreSymlink nushellInput;
        force = true;  # Overwrite if existing file/directory conflicts
      };
    })
  ];
}

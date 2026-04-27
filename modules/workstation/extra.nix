{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    surrealist        # SurrealDB GUI 客户端
    # 通讯
    telegram-desktop

    wps-office
    zathura         # PDF 阅读
    zathura-pdf-mupdf

    # 以下按需取消注释：
    # lapce
    # bruno           # API 客户端
    # penpot-desktop
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or "") [
      "wps-office"
    ];
}

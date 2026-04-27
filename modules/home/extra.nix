{ pkgs, ... }: {
  home.packages = with pkgs; [
    # 终端增强
    glow        # markdown 渲染
    fzf         # 模糊搜索

    # 数据分析
    duckdb      # 嵌入式 OLAP 数据库

    # 网络调试
    termshark   # 终端 WiShark/TShark 前端
  ];
}
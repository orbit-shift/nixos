{ ... }: {
  # ── Rime 输入法配置（雾凇拼音 + 小鹤双拼） ─────────────
  xdg.configFile."fcitx5/rime/default.yaml".text = ''
    schema_list:
      - schema: rime_ice              # 雾凇拼音全拼
      - schema: double_pinyin_flypy   # 小鹤双拼

    switcher:
      caption: 〔方案选单〕
      hotkeys:
        - Control+grave
        - Control+Shift+grave
        - F4
      save_options:
        - full_shape
        - ascii_punct
        - simplification
        - extended_charset
      fold_options: true
      abbreviate_options: true
      option_list_separator: '／'

    menu:
      page_size: 5
  '';
}

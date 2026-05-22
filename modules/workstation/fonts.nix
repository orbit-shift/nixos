{ pkgs, ... }: {
  # ── 字体配置 ───────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      lilex
      nerd-fonts.jetbrains-mono
      nerd-fonts.monaspace
    ];
    fontconfig = {
      enable = true;
      # hinting, antialias, rgba removed in newer nixpkgs;
      # use environment.etc for custom rules below.
      # ── 默认字体映射 ─────────────────────────────
      defaultFonts = {
        monospace = [ "Lilex" "MonaspiceAr" "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
        serif     = [ "Noto Serif" "Noto Serif CJK SC" ];
      };
    };
  };

  # Custom fontconfig rules (was fonts.fontconfig.conf/hinting/rgba, removed in newer nixpkgs)
  environment.etc."fonts/conf.d/99-custom-rendering.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <!-- enable antialias -->
      <match target="font">
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
      </match>
      <!-- hintstyle: slight（ARCH 默认） -->
      <match target="font">
        <edit name="hintstyle" mode="assign">
          <const>hintslight</const>
        </edit>
      </match>
      <!-- lcdfilter: default（ARCH 默认） -->
      <match target="font">
        <edit name="lcdfilter" mode="assign">
          <const>lcddefault</const>
        </edit>
      </match>
      <!-- rgb subpixel rendering -->
      <match target="font">
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>
      </match>
    </fontconfig>
  '';
}

{ pkgs, lib, config, ... }:

{
  options.nushell.musl = {
    url = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Nushell 官方 musl 二进制下载 URL。设置后启用 overlay 替换 nixpkgs 版本。";
    };

    sha256 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Nushell musl 二进制 sha256 校验。";
    };

    version = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Nushell 版本号。";
    };
  };

  config = let
    cfg = config.nushell.musl;
  in {
    nixpkgs.overlays = lib.optional (cfg.url != null && cfg.sha256 != null)
      (final: prev: {
        nushell = prev.stdenv.mkDerivation {
          pname = "nushell";
          inherit (cfg) version;

          src = prev.fetchurl {
            url = cfg.url;
            sha256 = cfg.sha256;
          };

          installPhase = ''
            mkdir -p $out/bin
            cp nu $out/bin/
            cp nufmt $out/bin/ 2>/dev/null || true
          '';

          doCheck = false;
          doInstallCheck = false;

          meta = {
            description = "A new type of shell (official musl binary)";
            homepage = "https://nushell.sh";
            license = prev.lib.licenses.mit;
            platforms = prev.lib.platforms.linux;
          };
        };
      });
  };
}

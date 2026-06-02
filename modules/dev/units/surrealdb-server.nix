{ pkgs, lib, config, ... }:

{
  options.surrealdb.server = {
    version = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SurrealDB 版本号。设置后启用 overlay 替换 nixpkgs 版本。";
    };

    rev = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SurrealDB GitHub 源码 rev（如 v3.0.5）。";
    };

    hash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SurrealDB fetchFromGitHub sha256。";
    };

    cargoHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SurrealDB cargoHash。";
    };

    enable = lib.mkEnableOption "SurrealDB 服务端";
  };

  config = let
    cfg = config.surrealdb.server;
  in {
    nixpkgs.overlays = lib.optional (cfg.version != null && cfg.hash != null && cfg.cargoHash != null)
      (final: prev: {
        surrealdb = prev.surrealdb.overrideAttrs (old: {
          inherit (cfg) version;
          src = prev.fetchFromGitHub {
            owner = "surrealdb";
            repo = "surrealdb";
            rev = cfg.rev;
            hash = cfg.hash;
          };
          inherit (cfg) cargoHash;
        });
      });

    services.surrealdb.enable = cfg.enable;
  };
}

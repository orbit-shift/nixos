{ pkgs, ... }: {
  # SurrealDB 服务端（局部 overlay 控制版本，不影响其他节点/包）
  nixpkgs.overlays = [
    (final: prev: {
      surrealdb = prev.surrealdb.overrideAttrs (old: {
        version = "3.0.5";
        src = prev.fetchFromGitHub {
          owner = "surrealdb";
          repo = "surrealdb";
          rev = "v3.0.5";
          hash = "sha256-H4hKTWF8yNOKThFh/ntojmYMYb8+xzziOAL2xlkUfSM=";
        };
        cargoHash = "sha256-gGaP9hIaiv7n+Izi3X8K9YpBJtPLXANI82lJy07ZMZI=";
      });
    })
  ];

  services.surrealdb = {
    enable = true;
  };
}

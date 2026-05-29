{ lib, config, ... }: {
  imports = [
    ./javascript.nix
    ./python.nix
    ./rust.nix
    ./haskell.nix
    ./c-cpp.nix
    ./wasm.nix
    ./k8s.nix
    ./data-tools.nix
    ./databases.nix
  ];

  config = {
    dev.javascript.enable = lib.mkDefault true;
    dev.python.enable = lib.mkDefault true;
    dev.rust.enable = lib.mkDefault true;
    dev.haskell.enable = lib.mkDefault true;
    dev.c-cpp.enable = lib.mkDefault true;
    dev.wasm.enable = lib.mkDefault true;
    dev.k8s.enable = lib.mkDefault true;
    dev.data-tools.enable = lib.mkDefault true;
    dev.databases.enable = lib.mkDefault true;
  };
}

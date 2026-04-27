{ pkgs, lib, ... }: {
  # ── Languages & Runtimes ──────────────────────────────────
  environment.systemPackages = with pkgs; [
    # JS/TS Runtime (Primary)
    bun

    # Python (with custom ecosystem) + uv
    uv
    (python3.withPackages (ps: with ps; [
      virtualenv
      httpx aiofile aiostream fastapi uvicorn
      debugpy pytest pydantic pyparsing
      ipython typer pydantic-settings pyyaml
      boltons decorator deepmerge
      structlog python-json-logger
      polars
    ]))

    # Rust Development
    rustup
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    sccache

    # Haskell Development
    haskellPackages.ghc
    haskellPackages.cabal-install
    haskellPackages.stack
    haskellPackages.haskell-language-server

    # WebAssembly
    wasmtime

    # C/C++ Build Tools
    gcc
    cmake
    gnumake
    pkg-config

    # K8s & Containers
    kubectl
    kubeadm
    kubernetes-helm

    # Data & Debugging
    duckdb
    termshark
  ];

  environment.variables = {
    RUSTC_WRAPPER = "sccache";
  };


}
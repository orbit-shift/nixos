```nix
{
  description = "A unified, production-grade Rust Flake: Dev, Check, Pack, and Docker";

  inputs = {
    # Pin to Rust-specific tooling overlay for precise version locking
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Initialize nixpkgs with the Rust compiler overlay
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Define the specific Rust toolchain version for the team
        rustVersion = "1.85.0"; # Example modern Rust stable channel
        rustToolchain = pkgs.rust-bin.stable.${rustVersion}.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" ];
        };

        # Shared Linux platform system libraries required by many heavy Rust crates
        # (e.g., openssl-sys, pkg-config, zlib)
        buildAndRuntimeDeps = [
          pkgs.openssl
          pkgs.zlib
        ];

        nativeDeps = [
          pkgs.pkg-config
        ];
      in
      {
        # =====================================================================
        # 1. APPLICATION PACKAGE (Strict native building & compilation sandboxing)
        # =====================================================================
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "rust-service";
          version = "1.0.0";
          src = ./.;

          # Provide our specific pinned compiler toolchain
          nativeBuildInputs = [ rustToolchain ] ++ nativeDeps;
          buildInputs = buildAndRuntimeDeps;

          # Use Cargo.lock directly for atomic evaluation caching
          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          # Inject compilation flags (e.g., dynamically locating static link paths)
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
        };

        # =====================================================================
        # 2. LOCAL DEV ENVIRONMENT (Instantly mapped to active terminal via direnv)
        # =====================================================================
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rustToolchain
            pkgs.cargo-watch  # Essential for live-reloading 'cargo watch -x run'
            pkgs.cargo-edit   # Easy package adding via 'cargo add'
          ] ++ buildAndRuntimeDeps;

          nativeBuildInputs = nativeDeps;

          shellHook = ''
            export RUST_BACKTRACE=1
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
            echo "🦀 High-performance Rust workspace loaded successfully!"
            rustc --version
          '';
        };

        # =====================================================================
        # 3. CODE VERIFICATION & SANITY GATES (Nix Hooks)
        # =====================================================================
        checks = {
          # Block local/CI compilation if code fails strict Clippy validation
          clippy = pkgs.runCommand "clippy-check" {
            nativeBuildInputs = [ rustToolchain ] ++ nativeDeps;
            buildInputs = buildAndRuntimeDeps;
          } ''
            cd ${./.}
            cargo clippy --all-targets -- -D warnings
            touch $out
          '';

          # Block build pipelines if rustfmt detects unformatted code blocks
          formatting = pkgs.runCommand "fmt-check" {
            nativeBuildInputs = [ rustToolchain ];
          } ''
            cd ${./.}
            cargo fmt -- --check
            touch $out
          '';
        };

        # =====================================================================
        # 4. GLOBAL FORMATTER PIPELINE
        # =====================================================================
        # Run 'nix fmt' globally to force standardized code-layout rules across the team
        formatter = rustToolchain;

        # =====================================================================
        # 5. DOCKER PRODUCTION IMAGE (Ultra-slim, secure, layered configuration)
        # =====================================================================
        packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
          name = "rust-production-service";
          tag = "latest";

          # Strict inclusion architecture: only copies OpenSSL and our final binary artifact.
          # There is no terminal shell, no Rust compiler, and zero build tool bloat inside.
          contents = [
            self.packages.${system}.default
            pkgs.cacert # Absolute requirement for secure TLS / HTTPS requests
          ];

          config = {
            # Directly points to the native binary path created in Step 1
            Cmd = [ "rust-service" ];
            Env = [
              "RUST_LOG=info"
              "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            ];
            ExposedPorts = {
              "8080/tcp" = {};
            };
          };
        };
      }
    );
}
```

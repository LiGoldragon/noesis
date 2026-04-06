{
  description = "Noesis — typed binary agent harness, capnp RPC replacing MCP JSON-RPC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    criome-cozo-src = { url = "github:LiGoldragon/criome-cozo/v1"; flake = false; };
    samskara-core-src = { url = "github:LiGoldragon/samskara-core/v1"; flake = false; };
    samskara-codegen-src = { url = "github:LiGoldragon/samskara-codegen/v1"; flake = false; };
    samskara-src = { url = "github:LiGoldragon/samskara"; flake = false; };
    noesis-schema-src = { url = "github:LiGoldragon/noesis-schema"; flake = false; };
    lojix-macros-src = { url = "github:LiGoldragon/lojix-macros"; flake = false; };
    sema-core-src = { url = "github:LiGoldragon/sema-core/v1"; flake = false; };
    sema-src = { url = "github:LiGoldragon/sema/v1"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, crane, fenix,
              criome-cozo-src, samskara-core-src, samskara-codegen-src,
              samskara-src, noesis-schema-src, lojix-macros-src,
              sema-core-src, sema-src, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rustToolchain = fenix.packages.${system}.latest.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        cozoFilter = path: _type: builtins.match ".*\\.cozo$" path != null;
        capnpFilter = path: _type: builtins.match ".*\\.capnp$" path != null;
        sourceFilter = path: type:
          (cozoFilter path type) || (capnpFilter path type) || (craneLib.filterCargoSources path type);
        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = sourceFilter;
        };

        # lojix-macros needs workspace-aware Cargo.toml when consumed here.
        # We copy its source and replace the Cargo.toml with workspace = true deps.
        lojixMacrosPatched = pkgs.runCommand "lojix-macros-patched" {} ''
          cp -rL ${lojix-macros-src} $out
          chmod -R u+w $out
          cat > $out/Cargo.toml << 'EOF'
[package]
name = "lojix-macros"
version = "0.1.0"
edition = "2024"
description = "Proc macros for deriving typed Rust code from samskara's datalog schema"
authors = ["Li Goldragon <li@goldragon.criome.net>"]

[lib]
proc-macro = true

[dependencies]
criome-cozo = { workspace = true }
samskara-codegen = { workspace = true }
samskara-core = { workspace = true }
sema-core = { workspace = true }
sema = { workspace = true }
syn = { version = "2", features = ["full"] }
quote = "1"
proc-macro2 = "1"
serde_json = "1.0"
EOF
        '';

        commonArgs = {
          inherit src;
          pname = "noesis";
          nativeBuildInputs = [ pkgs.capnproto ];
          postUnpack = ''
            mkdir -p $sourceRoot/flake-crates
            cp -rL ${criome-cozo-src} $sourceRoot/flake-crates/criome-cozo
            cp -rL ${samskara-core-src} $sourceRoot/flake-crates/samskara-core
            cp -rL ${samskara-codegen-src} $sourceRoot/flake-crates/samskara-codegen
            cp -rL ${samskara-src} $sourceRoot/flake-crates/samskara
            cp -rL ${noesis-schema-src} $sourceRoot/flake-crates/noesis-schema
            cp -rL ${sema-core-src} $sourceRoot/flake-crates/sema-core
            cp -rL ${sema-src} $sourceRoot/flake-crates/sema
            cp -rL ${lojixMacrosPatched} $sourceRoot/flake-crates/lojix-macros
            chmod -R u+w $sourceRoot/flake-crates/lojix-macros
            # lojix-macros include_str! needs schema files relative to its CARGO_MANIFEST_DIR
            mkdir -p $sourceRoot/flake-crates/lojix-macros/flake-crates
            ln -sf ../../samskara $sourceRoot/flake-crates/lojix-macros/flake-crates/samskara
            ln -sf ../../noesis-schema $sourceRoot/flake-crates/lojix-macros/flake-crates/noesis-schema
            ln -sf ../../sema-core $sourceRoot/flake-crates/lojix-macros/flake-crates/sema-core
            ln -sf ../../sema $sourceRoot/flake-crates/lojix-macros/flake-crates/sema
          '';
        };
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;
      in
      {
        packages.default = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

        checks = {
          build = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
          });
          tests = craneLib.cargoTest (commonArgs // {
            inherit cargoArtifacts;
          });
        };

        devShells.default = craneLib.devShell {
          packages = with pkgs; [ rust-analyzer sqlite jujutsu capnproto ];
        };
      }
    );
}

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
    criome-cozo-src = { url = "github:LiGoldragon/criome-cozo"; flake = false; };
    samskara-core-src = { url = "github:LiGoldragon/samskara-core"; flake = false; };
    samskara-codegen-src = { url = "github:LiGoldragon/samskara-codegen"; flake = false; };
    samskara-src = { url = "github:LiGoldragon/samskara"; flake = false; };
    noesis-schema-src = { url = "github:LiGoldragon/noesis-schema"; flake = false; };
    lojix-macros-src = { url = "github:LiGoldragon/lojix-macros"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, crane, fenix,
              criome-cozo-src, samskara-core-src, samskara-codegen-src,
              samskara-src, noesis-schema-src, lojix-macros-src, ... }:
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

        # lojix-macros needs its own flake-crates inside its source tree.
        # We create a modified copy with workspace-aware Cargo.toml.
        lojixMacrosPatched = pkgs.runCommand "lojix-macros-patched" {} ''
          cp -rL ${lojix-macros-src} $out
          chmod -R u+w $out

          # Replace path deps with workspace deps
          cat > $out/Cargo.toml << 'TOML'
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
          syn = { version = "2", features = ["full"] }
          quote = "1"
          proc-macro2 = "1"
          serde_json = "1.0"
          TOML

          # Create flake-crates pointing to workspace root's copies
          mkdir -p $out/flake-crates
          ln -s ../../criome-cozo $out/flake-crates/criome-cozo
          ln -s ../../samskara-core $out/flake-crates/samskara-core
          ln -s ../../samskara-codegen $out/flake-crates/samskara-codegen
          ln -s ../../samskara $out/flake-crates/samskara
          ln -s ../../noesis-schema $out/flake-crates/noesis-schema
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
            cp -rL ${lojixMacrosPatched} $sourceRoot/flake-crates/lojix-macros
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

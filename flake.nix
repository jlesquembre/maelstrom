{
  description = "A clj-nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    clj-nix = {
      url = "github:jlesquembre/clj-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, clj-nix }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ]
          (system: function rec {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
            cljpkgs = clj-nix.packages."${system}";
          });
    in
    {
      packages = forAllSystems ({ cljpkgs, pkgs, ... }: {
        default = cljpkgs.mkCljBin {
          buildCommand = ''
            BUILD_DIR="maelstrom"
            export jarPath="$BUILD_DIR/maelstrom.jar"
            mkdir -p $BUILD_DIR
            lein do clean, run doc, uberjar
            cp target/maelstrom-*-standalone.jar "$jarPath"
          '';
          projectSrc = ./.;
          name = "maelstrom";
          main-ns = "maelstrom.core";
          java-opts = [ "-Djava.awt.headless=true" ];
        };
      });
    };

}

{
  description = "Generate a tags file for Haskell projects that are built with nix";

  inputs = {
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";
    nixpkgs-stable-linux.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    nix-project.url = "github:shajra/nix-project";
    flake-compat = { url = "github:nix-community/flake-compat"; flake = false; };
  };

  outputs = inputs @ { flake-parts, ... }: let
    overlay = import ./nix/overlay.nix;
    in flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        nix/module/nixpkgs.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem = { nixpkgs, ... }:
      let build = nixpkgs.stable.appendOverlays [
        overlay
        inputs.nix-project.overlays.default
      ];
      in {
        packages = rec {
          default = haskell-tags-nix-exe;
          inherit (build)
            haskell-tags-nix-exe;
        };
        legacyPackages.lib = {
          inherit (build)
            haskell-tags-nix-dynamic
            haskell-tags-nix-static
            run-dynamic
            run-static;
        };
      };
      flake = {
        overlays.default = overlay;
      };
    };
}

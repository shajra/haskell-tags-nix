{ externalOverrides ? {}
}:

let

    external = import ./external // externalOverrides;

    overlay = self: super: {
        args = pkgs.callPackage (import ./args.nix) {};
        deps-haskellNix = self.callPackage (import ./deps-haskellnix.nix) {};
        deps-nixpkgs = self.callPackage (import ./deps-nixpkgs.nix) {};
        deps-set = self.callPackage (import ./deps-set.nix) {};
        deps-srcs = self.callPackage (import ./deps-srcs.nix) {};
        deps-unpack = self.callPackage (import ./deps-unpack.nix) {};
        nix-project-lib = (import external.nix-project).nix-project-lib;
        tags-dynamic = pkgs.callPackage (import ./tags-dynamic.nix) {};
        tags-static = pkgs.callPackage (import ./tags-static.nix) {};
    };

    pkgs = import external.nixpkgs-stable { config = {}; overlays = [overlay]; };

    nix-project = import external.nix-project;

    run-dynamic = pkgs.callPackage (import ./run-dynamic.nix) {};
    nix-haskell-tags-dynamic = pkgs.callPackage (import ./eval-dynamic.nix) {};
    run-static = pkgs.callPackage (import ./run-static.nix) {};
    nix-haskell-tags-static = pkgs.callPackage (import ./eval-static.nix) {};
    nix-haskell-tags-exe = pkgs.callPackage (import ./run.nix) {};

in

nix-project // {
    inherit
    pkgs
    run-dynamic
    nix-haskell-tags-dynamic
    run-static
    nix-haskell-tags-static
    nix-haskell-tags-exe;
}

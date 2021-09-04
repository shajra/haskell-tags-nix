{ externalOverrides ? {}
}:

let

    external = import ./external // externalOverrides;

    nix-project = import external.nix-project;

    overlay = self: super: nix-project // {

        args = nixpkgs.callPackage (import ./args.nix) {};
        deps-haskellNix = self.callPackage (import ./deps-haskellnix.nix) {};
        deps-nixpkgs = self.callPackage (import ./deps-nixpkgs.nix) {};
        deps-set = self.callPackage (import ./deps-set.nix) {};
        deps-srcs = self.callPackage (import ./deps-srcs.nix) {};
        deps-unpack = self.callPackage (import ./deps-unpack.nix) {};
        nix-project-lib = (import external.nix-project).nix-project-lib;
        tags-dynamic = nixpkgs.callPackage (import ./tags-dynamic.nix) {};
        tags-static = nixpkgs.callPackage (import ./tags-static.nix) {};

        run-dynamic = nixpkgs.callPackage (import ./run-dynamic.nix) {};
        haskell-tags-nix-dynamic = nixpkgs.callPackage (import ./eval-dynamic.nix) {};
        run-static = nixpkgs.callPackage (import ./run-static.nix) {};
        haskell-tags-nix-static = nixpkgs.callPackage (import ./eval-static.nix) {};
        haskell-tags-nix-exe = nixpkgs.callPackage (import ./run.nix) {};

    };


    nixpkgs = import external.nixpkgs-stable { config = {}; overlays = [overlay]; };

    distribution = {
        inherit (nixpkgs)
        haskell-tags-nix-exe
        haskell-tags-nix-dynamic
        haskell-tags-nix-static;
    };

    build = distribution // {
        inherit (nixpkgs)
        run-dynamic
        run-static;
    };

in {
    inherit
    distribution
    build
    nix-project
    nixpkgs;
}

{ externalOverrides ? {}
}:

let

    external = import ./external // externalOverrides;

    overlay = self: super: import external.nix-project // {

        args = pkgs.callPackage (import ./args.nix) {};
        deps-haskellNix = self.callPackage (import ./deps-haskellnix.nix) {};
        deps-nixpkgs = self.callPackage (import ./deps-nixpkgs.nix) {};
        deps-set = self.callPackage (import ./deps-set.nix) {};
        deps-srcs = self.callPackage (import ./deps-srcs.nix) {};
        deps-unpack = self.callPackage (import ./deps-unpack.nix) {};
        nix-project-lib = (import external.nix-project).nix-project-lib;
        tags-dynamic = pkgs.callPackage (import ./tags-dynamic.nix) {};
        tags-static = pkgs.callPackage (import ./tags-static.nix) {};

        run-dynamic = pkgs.callPackage (import ./run-dynamic.nix) {};
        haskell-tags-nix-dynamic = pkgs.callPackage (import ./eval-dynamic.nix) {};
        run-static = pkgs.callPackage (import ./run-static.nix) {};
        haskell-tags-nix-static = pkgs.callPackage (import ./eval-static.nix) {};
        haskell-tags-nix-exe = pkgs.callPackage (import ./run.nix) {};

    };

    pkgs = import external.nixpkgs-stable { config = {}; overlays = [overlay]; };


in pkgs

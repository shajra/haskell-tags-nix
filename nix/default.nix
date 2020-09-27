{ sources ? import ./sources.nix
}:

let

    overlay = self: super: {
        nix-project-lib = (import sources.nix-project).nix-project-lib;
        unpack = self.callPackage (import ./unpack.nix) {};
        set = self.callPackage (import ./set.nix) {};
        srcs-haskellNix = self.callPackage (import ./srcs-haskellnix.nix) {};
        srcs-nixpkgs = self.callPackage (import ./srcs-nixpkgs.nix) {};
        nix-haskell-tags-lib = pkgs.callPackage (import ./tags.nix) {};
    };

    pkgs = import sources.nixpkgs { config = {}; overlays = [overlay]; };

    nix-project = import sources.nix-project;

    nix-haskell-tags-run = pkgs.callPackage (import ./tags-run.nix) {};
    nix-haskell-tags-eval = pkgs.callPackage (import ./tags-eval.nix) {};
    nix-haskell-tags-exe = pkgs.callPackage (import ./run.nix) {};

in

nix-project // {
    inherit
    pkgs
    nix-haskell-tags-run
    nix-haskell-tags-eval
    nix-haskell-tags-exe;
}

final: prev: {
  args = final.pkgs.callPackage (import ./args.nix) {};
  deps-haskellNix = prev.pkgs.callPackage (import ./deps-haskellnix.nix) {};
  deps-nixpkgs = prev.pkgs.callPackage (import ./deps-nixpkgs.nix) {};
  deps-set = prev.pkgs.callPackage (import ./deps-set.nix) {};
  deps-srcs = prev.pkgs.callPackage (import ./deps-srcs.nix) {};
  deps-unpack = prev.pkgs.callPackage (import ./deps-unpack.nix) {};
  tags-dynamic = prev.pkgs.callPackage (import ./tags-dynamic.nix) {};
  tags-static = prev.pkgs.callPackage (import ./tags-static.nix) {};

  run-dynamic = prev.pkgs.callPackage (import ./run-dynamic.nix) {};
  haskell-tags-nix-dynamic = final.pkgs.callPackage (import ./eval-dynamic.nix) {};
  run-static = final.pkgs.callPackage (import ./run-static.nix) {};
  haskell-tags-nix-static = final.pkgs.callPackage (import ./eval-static.nix) {};
  haskell-tags-nix-exe = final.pkgs.callPackage (import ./run.nix) {};
}


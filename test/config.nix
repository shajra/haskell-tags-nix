{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-05-21T00:00:00Z";
        sha256 = "b7eba21b59256ebfe35603e91d406376a363589bedc7a03e82e5854f51ac046f";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
    haskell-nix.ghcVersion = "ghc8104";
    nixpkgs.distribution = "unstable";
    nixpkgs.ghcVersion = "ghc8104";
}

{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-02-21T00:00:00Z";
        sha256 = "9bdefd7052080d8989f398de529973e993d2911993b6c2fb9cfe801dad47879d";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
    haskell-nix.ghcVersion = "ghc8104";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8103";
}

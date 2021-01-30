{
    ghcVersion = "ghc8103";
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-01-24T00:00:00Z";
        sha256 = "072c1d30ac3111a527f6647c8b646c0774fe382269a902c9e6e4fc1c18772f31";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
}

{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-07-25T00:00:00Z";
        sha256 = "d01e60cc933f805b6f5e85d128f445cd07dbf12b14f010ee71c6dadd1bd9626b";
    };

    # DESIGN: The GHCs used to compile in each infrastructure don't have to
    # match.  Do what's convenient to get a cache hit.
    haskell-nix.nixpkgs-pin = "nixpkgs-2105";
    haskell-nix.ghcVersion = "ghc8105";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8104";
}

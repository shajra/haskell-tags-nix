{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-08-08T00:00:00Z";
        sha256 = "e8aed582a6afc4a82127cdbc976d3aac700a4660fc1c4770170c3fe0443bea68";
    };

    # DESIGN: The GHCs used to compile in each infrastructure don't have to
    # match.  Do what's convenient to get a cache hit.
    haskell-nix.nixpkgs-pin = "nixpkgs-2105";
    haskell-nix.ghcVersion = "ghc8105";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8104";
}

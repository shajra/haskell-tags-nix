{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-09-01T00:00:00Z";
        sha256 = "934338f5c73d91ee7dfdcb838ac44e8d92d5306aa60582cdded7abae887a7646";
    };

    # DESIGN: The GHCs used to compile in each infrastructure don't have to
    # match.  Do what's convenient to get a cache hit.
    haskell-nix.nixpkgs-pin = "nixpkgs-2105";
    haskell-nix.ghcVersion = "ghc8107";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8104";
}

{
    haskell-nix.checkMaterialization = false;

    # DESIGN: The GHCs used to compile in each infrastructure don't have to
    # match.  Do what's convenient to get a cache hit.
    haskell-nix.nixpkgs-pin = "nixpkgs-2105";
    haskell-nix.ghcVersion = "ghc8107";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8104";
}

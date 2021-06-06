{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-06-05T00:00:00Z";
        sha256 = "4f26c87b07934f38578b1ceb204923166eb1dee317421509da9a080cb93efadb";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
    haskell-nix.ghcVersion = "ghc8104";
    nixpkgs.distribution = "unstable";
    nixpkgs.ghcVersion = "ghc8104";
}

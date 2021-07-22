{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-07-22T00:00:00Z";
        sha256 = "b9a81bc5709932aac9dcd9507bab236a96099112484cee7a6fb01f9da52f3fa2";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
    haskell-nix.ghcVersion = "ghc8104";
    nixpkgs.distribution = "unstable";
    nixpkgs.ghcVersion = "ghc8104";
}

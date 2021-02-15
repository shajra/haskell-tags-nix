{
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.hackage.index = {
        state = "2021-02-14T00:00:00Z";
        sha256 = "db71cd0dfe6bb7957b52b50ab8cb268f9debe65a37a1983451ec610ae143c59b";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
    haskell-nix.ghcVersion = "ghc8104";
    nixpkgs.distribution = "stable";
    nixpkgs.ghcVersion = "ghc8103";
}

{
    ghcVersion = "ghc884";
    haskell-nix.useMaterialization = true;
    haskell-nix.checkMaterialization = false;
    # DESIGN: https://github.com/input-output-hk/hackage.nix/blob/master/index-state-hashes.nix
    haskell-nix.plan-sha256 = "0r15xdh6ij55sc7xdlp0qcp0lid2pswcqpikvrlpp9fqxw44kq3j";
    haskell-nix.hackage.index = {
        state = "2020-12-28T00:00:00Z";
        sha256 = "ce5696846e316c2d151c69f5f292dfe1aceca540253757831d9081990a2a1d90";
    };
    haskell-nix.nixpkgs-pin = "nixpkgs-2009";
}

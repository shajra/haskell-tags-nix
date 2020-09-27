with (import ./nix {}); {
    inherit
    nix-haskell-tags-run
    nix-haskell-tags-eval
    nix-haskell-tags-exe;
}

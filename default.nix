with (import ./nix {}); {
    inherit
    nix-haskell-tags-exe
    nix-haskell-tags-dynamic
    nix-haskell-tags-static;
}

with (import ./nix {}); {
    inherit
    haskell-tags-nix-exe
    haskell-tags-nix-dynamic
    haskell-tags-nix-static;
}

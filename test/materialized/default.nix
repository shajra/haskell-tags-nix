{
  pkgs = hackage:
    {
      packages = {
        "void".revision = (((hackage."void")."0.7.3").revisions).default;
        "void".flags.safe = false;
        "ghc-prim".revision = (((hackage."ghc-prim")."0.5.3").revisions).default;
        "rts".revision = (((hackage."rts")."1.0").revisions).default;
        "base".revision = (((hackage."base")."4.13.0.0").revisions).default;
        "integer-gmp".revision = (((hackage."integer-gmp")."1.0.2.0").revisions).default;
        };
      compiler = {
        version = "8.8.4";
        nix-name = "ghc884";
        packages = {
          "ghc-prim" = "0.5.3";
          "rts" = "1.0";
          "base" = "4.13.0.0";
          "integer-gmp" = "1.0.2.0";
          };
        };
      };
  extras = hackage:
    {
      packages = {
        nix-haskell-tags-example = ./.plan.nix/nix-haskell-tags-example.nix;
        };
      };
  modules = [
    ({ lib, ... }:
      { packages = { "nix-haskell-tags-example" = { flags = {}; }; }; })
    ];
  }
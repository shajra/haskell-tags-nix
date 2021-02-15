{
  pkgs = hackage:
    {
      packages = {
        "void".revision = (((hackage."void")."0.7.3").revisions).default;
        "void".flags.safe = false;
        "ghc-prim".revision = (((hackage."ghc-prim")."0.6.1").revisions).default;
        "rts".revision = (((hackage."rts")."1.0").revisions).default;
        "base".revision = (((hackage."base")."4.14.1.0").revisions).default;
        "integer-gmp".revision = (((hackage."integer-gmp")."1.0.3.0").revisions).default;
        };
      compiler = {
        version = "8.10.4";
        nix-name = "ghc8104";
        packages = {
          "ghc-prim" = "0.6.1";
          "rts" = "1.0";
          "base" = "4.14.1.0";
          "integer-gmp" = "1.0.3.0";
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
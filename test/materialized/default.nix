{
  pkgs = hackage:
    {
      packages = {
        "ghc-prim".revision = (((hackage."ghc-prim")."0.6.1").revisions).default;
        "void".revision = (((hackage."void")."0.7.3").revisions).default;
        "void".flags.safe = false;
        "integer-gmp".revision = (((hackage."integer-gmp")."1.0.3.0").revisions).default;
        "base".revision = (((hackage."base")."4.14.2.0").revisions).default;
        "rts".revision = (((hackage."rts")."1.0.1").revisions).default;
        };
      compiler = {
        version = "8.10.5";
        nix-name = "ghc8105";
        packages = {
          "ghc-prim" = "0.6.1";
          "integer-gmp" = "1.0.3.0";
          "base" = "4.14.2.0";
          "rts" = "1.0.1";
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
    ({ lib, ... }:
      {
        packages = {
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "nix-haskell-tags-example".components.exes."nix-haskell-tags-example".planned = lib.mkOverride 900 true;
          "integer-gmp".components.library.planned = lib.mkOverride 900 true;
          "void".components.library.planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          };
        })
    ];
  }
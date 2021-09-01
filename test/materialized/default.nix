{
  pkgs = hackage:
    {
      packages = {
        "ghc-prim".revision = (((hackage."ghc-prim")."0.6.1").revisions).default;
        "void".revision = (((hackage."void")."0.7.3").revisions).default;
        "void".flags.safe = false;
        "integer-gmp".revision = (((hackage."integer-gmp")."1.0.3.0").revisions).default;
        "base".revision = (((hackage."base")."4.14.3.0").revisions).default;
        "rts".revision = (((hackage."rts")."1.0.1").revisions).default;
        };
      compiler = {
        version = "8.10.7";
        nix-name = "ghc8107";
        packages = {
          "ghc-prim" = "0.6.1";
          "integer-gmp" = "1.0.3.0";
          "base" = "4.14.3.0";
          "rts" = "1.0.1";
          };
        };
      };
  extras = hackage:
    {
      packages = {
        haskell-tags-nix-example = ./.plan.nix/haskell-tags-nix-example.nix;
        };
      };
  modules = [
    ({ lib, ... }:
      { packages = { "haskell-tags-nix-example" = { flags = {}; }; }; })
    ({ lib, ... }:
      {
        packages = {
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "haskell-tags-nix-example".components.exes."haskell-tags-nix-example".planned = lib.mkOverride 900 true;
          "integer-gmp".components.library.planned = lib.mkOverride 900 true;
          "void".components.library.planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          };
        })
    ];
  }
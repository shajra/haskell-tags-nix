{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = {};
    package = {
      specVersion = "1.10";
      identifier = { name = "nix-haskell-tags-example"; version = "0.1.0.0"; };
      license = "NONE";
      copyright = "";
      maintainer = "rrudbskr5g@snkmail.com";
      author = "Sukant Hajra";
      homepage = "";
      url = "";
      synopsis = "";
      description = "";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [];
      dataDir = "";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      exes = {
        "nix-haskell-tags-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."void" or (errorHandler.buildDepError "void"))
            ];
          buildable = true;
          hsSourceDirs = [ "src" ];
          mainPath = [ "Main.hs" ];
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault ../.; }
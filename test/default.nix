{ externalOverrides ? {}
, config ? import ./config.nix
, checkMaterialization ? false
}:

let

    external = import ../nix/external // externalOverrides;

    nixpkgs = import external."nixpkgs-${config.nixpkgs.distribution}" {
        config = {}; overlays = [];
    };

    lib = nixpkgs.lib;

    cleanSrc = nixpkgs.lib.sourceFilesBySuffices;

    haskell-nix =
        let hn = import external."haskell.nix" {};
            nixpkgsSrc = hn.sources."${config.haskell-nix.nixpkgs-pin}";
            nixpkgsOrigArgs = hn.nixpkgsArgs;
            nixpkgsArgs = nixpkgsOrigArgs // { config = {}; };
        in (import nixpkgsSrc nixpkgsArgs).haskell-nix;

    src.example = cleanSrc ./example [".hs" ".cabal" "cabal.project"];

    infra.nixpkgs = nixpkgs;
    infra.haskell-nix = haskell-nix;

    build.nixpkgs =
        nixpkgs.haskell.packages.${config.nixpkgs.ghcVersion}.callCabal2nix
            "haskell-tags-nix-example" src.example {};

    build.haskell-nix = (haskell-nix.project {
        name = "haskell-tags-nix-example-haskellnix";
        src = src.example;
        compiler-nix-name = config.haskell-nix.ghcVersion;
        materialized = ./materialized;
        inherit checkMaterialization;
    }).haskell-tags-nix-example;

    tagsMake.common = (import ../nix {}).build.run-static;

    tagsMake.nixpkgs = args: tagsMake.common ({
        haskellNix = false;
        nixFile = ./.;
        attrPaths = [ "build.nixpkgs" ];
    } // args);

    tagsMake.haskell-nix = check: args: tagsMake.common ({
        haskellNix = true;
        nixFile = ./.;
        attrPaths = [ "build.haskell-nix" ];
        exprArg = { checkMaterialization = check; };
    } // args);

    option.buildType.np.tagsMake = tagsMake.nixpkgs;
    option.buildType.np.name = "nixpkgs-cabal";
    option.buildType.hn.tagsMake = tagsMake.haskell-nix checkMaterialization;
    option.buildType.hn.name = "haskellnix";
    option.buildType.hn-noMatCheck.tagsMake = tagsMake.haskell-nix false;
    option.buildType.hn-noMatCheck.name = "haskellnix";
    option.ghcTags.includeGhc.value = true;
    option.ghcTags.includeGhc.name = "includeGhc";
    option.ghcTags.excludeGhc.value = false;
    option.ghcTags.excludeGhc.name = "excludeGhc";
    option.targetTags.includeTargets.value = true;
    option.targetTags.includeTargets.name = "includeTargets";
    option.targetTags.excludeTargets.value = false;
    option.targetTags.excludeTargets.name = "excludeTargets";
    option.format.etags.value = true;
    option.format.etags.name = "etags";
    option.format.ctags.value = false;
    option.format.ctags.name = "ctags";

    testName = buildType: includeGhc: includeTargets: format:
        lib.concatStringsSep "-" [
            "test"
            buildType.name
            includeGhc.name
            includeTargets.name
            format.name
        ];

    tag = buildType: includeGhc: includeTargets: format:
        buildType.tagsMake {
            includeGhc = includeGhc.value;
            includeTargets = includeTargets.value;
            emacs = format.value;
        };

    test = buildType: includeGhc: includeTargets: format:
        let tags = buildType.tagsMake {
                includeGhc = includeGhc.value;
                includeTargets = includeTargets.value;
                emacs = format.value;
            };
        in tags.overrideAttrs (old: {
            name = testName buildType includeGhc includeTargets format;
            phases = old.phases ++ ["checkPhase"];
            src = cleanSrc ./. [".bats"];
            nativeBuildInputs = with nixpkgs;
                old.nativeBuildInputs ++ [ bats gnugrep ];
            doCheck = true;
            BUILD_NAME = buildType.name;
            INCLUDE_GHC_VALUE = includeGhc.value;
            INCLUDE_GHC_NAME = includeGhc.name;
            INCLUDE_TARGETS_VALUE = includeTargets.value;
            INCLUDE_TARGETS_NAME = includeTargets.name;
            FORMAT_NAME = format.name;
            checkPhase = ''bats $src/test-tags.bats'';
        });

    testMake = buildType: includeGhc: includeTargets: format:
        let key = testName buildType includeGhc includeTargets format;
            val = test buildType includeGhc includeTargets format;
        in { "${key}" = val; };

in with option; with buildType; with ghcTags; with targetTags; with format;
    { inherit build infra; }
    // testMake np            includeGhc includeTargets ctags
    // testMake np            includeGhc includeTargets etags
    // testMake np            includeGhc excludeTargets ctags
    // testMake np            includeGhc excludeTargets etags
    // testMake np            excludeGhc includeTargets ctags
    // testMake np            excludeGhc includeTargets etags
    // testMake np            excludeGhc excludeTargets ctags
    // testMake np            excludeGhc excludeTargets etags
    // testMake hn            includeGhc includeTargets ctags
    // testMake hn-noMatCheck includeGhc includeTargets etags
    // testMake hn-noMatCheck includeGhc excludeTargets ctags
    // testMake hn-noMatCheck includeGhc excludeTargets etags
    // testMake hn-noMatCheck excludeGhc includeTargets ctags
    // testMake hn-noMatCheck excludeGhc includeTargets etags
    // testMake hn-noMatCheck excludeGhc excludeTargets ctags
    // testMake hn-noMatCheck excludeGhc excludeTargets etags

{ sources ? import ../nix/sources.nix
, nixpkgs ? import sources.nixpkgs { config = {}; overlays = []; }
, config ? import ./config.nix
}:

let

    cleanSrc = nixpkgs.lib.sourceFilesBySuffices;

    haskell-nix =
        let hn = import sources."haskell.nix" {};
            nixpkgsSrc = hn.sources."${config.haskell-nix.nixpkgs-pin}";
            nixpkgsOrigArgs = hn.nixpkgsArgs;
            nixpkgsArgs = nixpkgsOrigArgs // { config = {}; };
        in (import nixpkgsSrc nixpkgsArgs).haskell-nix;

    src.example = cleanSrc ./example [".hs" ".cabal"];

    build.nixpkgs =
        nixpkgs.pkgs.haskell.packages.${config.ghcVersion}.callCabal2nix
            "nix-haskell-tags-example" src.example {};

    build.haskell-nix = (haskell-nix.project {
        name = "nix-haskell-tags-example-haskellnix";
        src = src.example;
        compiler-nix-name = config.ghcVersion;
        index-state = config.haskell-nix.hackage.index.state;
        index-sha256 = config.haskell-nix.hackage.index.sha256;
    }).nix-haskell-tags-example;

    tags-run = (import ../nix {}).run-static;

    tags-make.nixpkgs = args: tags-run ({
        haskellNix = false;
        nixFile = import ./.;
        attrPaths = [ "build.nixpkgs" ];
    } // args);

    tags-make.haskell-nix = args: tags-run ({
        haskellNix = true;
        nixFile = import ./.;
        attrPaths = [ "build.haskell-nix" ];
    } // args);

    test = buildType: includeGhc: includeTargets: emacs:
        let buildTags =
                if buildType == "nixpkgs"
                then tags-make.nixpkgs
                else tags-make.haskell-nix;
            includeGhcStr = if includeGhc then "ghc" else "noghc";
            includeTargetStr = if includeTargets then "target" else "notarget";
            emacsStr = if emacs then "emacs" else "vim";
            tags = buildTags { inherit includeGhc includeTargets emacs; };
        in tags.overrideAttrs (old: {
            name = "nix-haskell-tags-test-${buildType}-${emacsStr}-${includeGhcStr}-${includeTargetStr}";
            phases = old.phases ++ ["checkPhase"];
            src = cleanSrc ./. [".bats"];
            nativeBuildInputs = with nixpkgs;
                old.nativeBuildInputs ++ [ bats gnugrep ];
            doCheck = true;
            BUILD_TYPE =
                if buildType == "nixpkgs" then "Nixpkgs" else "Haskell.nix";
            EDITOR= if includeGhc then "true" else "false";
            INCLUDE_GHC= if includeGhc then "true" else "false";
            INCLUDE_TARGET= if includeTargets then "true" else "false";
            EMACS = emacsStr;
            checkPhase = ''
                bats $src/test-tags.bats
            '';
        });

in {
    inherit build;
    test-nixpkgs-vim-f-f = test "nixpkgs" false false false;
    test-nixpkgs-vim-f-t = test "nixpkgs" false false true;
    test-nixpkgs-vim-t-f = test "nixpkgs" false true false;
    test-nixpkgs-vim-t-t = test "nixpkgs" false true true;
    test-haskellnix-vim-f-f = test "haskellnix" false false false;
    test-haskellnix-vim-f-t = test "haskellnix" false false true;
    test-haskellnix-vim-t-f = test "haskellnix" false true false;
    test-haskellnix-vim-t-t = test "haskellnix" false true true;
    test-nixpkgs-emacs-f-f = test "nixpkgs" true false false;
    test-nixpkgs-emacs-f-t = test "nixpkgs" true false true;
    test-nixpkgs-emacs-t-f = test "nixpkgs" true true false;
    test-nixpkgs-emacs-t-t = test "nixpkgs" true true true;
    test-haskellnix-emacs-f-f = test "haskellnix" true false false;
    test-haskellnix-emacs-f-t = test "haskellnix" true false true;
    test-haskellnix-emacs-t-f = test "haskellnix" true true false;
    test-haskellnix-emacs-t-t = test "haskellnix" true true true;
}

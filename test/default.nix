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

    tags-run = (import ../.).nix-haskell-tags-run;

    tags-make.nixpkgs = includeAll: tags-run {
        haskellNix = false;
        nixFile = import ./.;
        attrPaths = [ "build.nixpkgs" ];
        inherit includeAll;
    };

    tags-make.haskell-nix = includeAll: tags-run {
        haskellNix = true;
        nixFile = import ./.;
        attrPaths = [ "build.haskell-nix" ];
        inherit includeAll;
    };

    test = buildType: includeAll:
        let tags =
                if buildType == "nixpkgs"
                then tags-make.nixpkgs
                else tags-make.haskell-nix;
            includeStr = if includeAll then "all" else "dependencies";
        in (tags includeAll).overrideAttrs (old: {
            name = "nix-haskell-tags-test-${buildType}-${includeStr}";
            phases = old.phases ++ ["checkPhase"];
            src = cleanSrc ./. [".bats"];
            nativeBuildInputs = with nixpkgs;
                old.nativeBuildInputs ++ [ bats gnugrep ];
            doCheck = true;
            BUILD_TYPE =
                if buildType == "nixpkgs" then "Nixpkgs" else "Haskell.nix";
            INCLUDE_ALL= if includeAll then "true" else "false";
            checkPhase = ''
                bats $src/test-tags.bats
            '';
        });

in {
    inherit build;
    test-nixpkgs-dependencies = test "nixpkgs" false;
    test-nixpkgs-all = test "nixpkgs" true;
    test-haskellnix-dependencies = test "haskellnix" false;
    test-haskellnix-all = test "haskellnix" true;
}

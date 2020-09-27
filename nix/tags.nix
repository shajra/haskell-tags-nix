{ stdenv
, lib
, haskellPackages
, unpack
, srcs-haskellNix
, srcs-nixpkgs
}:

{ annotatedNixExprs
, haskellNix ? false
, emacs ? false
, includeAll ? false
, exclude ? ""
, followSymlinks ? false
, noModuleTags ? false
, qualified ? false
, fullyQualified ? false
, srcPrefix ? ""
}:

let

    args.emacs = if emacs then "--emacs" else "";
    args.exclude = if exclude == "" then "" else "--exclude='${exclude}'";
    args.followSymlinks = if followSymlinks then "--follow-symlinks" else "";
    args.noModuleTags = if noModuleTags then "--no-module-tags" else "";
    args.qualified = if qualified then "--qualified" else "";
    args.fullyQualified = if fullyQualified then "--fully-qualified" else "";
    args.srcPrefix =
        if srcPrefix == "" then "" else "--src-prefix='${srcPrefix}'";

    libSrc = if haskellNix then srcs-haskellNix else srcs-nixpkgs;

    depSrcs =
        let init = { initial = {}; all = {}; };
            merged = builtins.foldl' libSrc init annotatedNixExprs;
            pruned = builtins.removeAttrs merged.all
                (builtins.attrNames merged.initial);
            pruneMaybe = if includeAll then merged.all else pruned;
        in builtins.map unpack.unpackMaybe (builtins.attrValues pruneMaybe);

    onlyInStore = builtins.filter (lib.hasPrefix builtins.storeDir);

    toStoreRoots = ss: lib.unique
        (builtins.map
            (s: lib.concatStringsSep "/"
                (lib.take 4 (lib.splitString "/" "${s}"))) ss);

    dependencies =
        lib.concatStringsSep " " (toStoreRoots (onlyInStore depSrcs));

    tags = stdenv.mkDerivation {
        name = "tags";
        phases = [ "installPhase" ];
        nativeBuildInputs = [ haskellPackages.fast-tags ];
        installPhase = ''
            fast-tags -R -o "$out" \
                ${args.emacs} \
                ${args.exclude} \
                ${args.followSymlinks} \
                ${args.noModuleTags} \
                ${args.qualified} \
                ${args.fullyQualified} \
                ${args.srcPrefix} \
                ${dependencies}
            if ! [ -f "$out" ]
            then
                echo "ERROR: no Haskell source found to tag" >&2
                exit 1
            fi
        '';
    };

in tags

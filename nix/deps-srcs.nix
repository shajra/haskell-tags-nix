{ deps-unpack
, deps-haskellNix
, deps-nixpkgs
}:

{ annotatedNixExprs
, haskellNix
, includeGhc
, includeTargets
, static
}:

let

    libSrc = if haskellNix then deps-haskellNix else deps-nixpkgs;
    init = { initial = {}; all = {}; ghc = {}; };
    merged = builtins.foldl' libSrc init annotatedNixExprs;
    pruned = builtins.removeAttrs merged.all
        (builtins.attrNames merged.initial);
    pruneMaybe = if includeTargets then merged.all else pruned;
    all = if includeGhc then pruneMaybe // merged.ghc else pruneMaybe;
    toStoreMaybe =
        if static
        then (s: "${s}")
        else (s: builtins.toString (if s ? origSrc then s.origSrc else s));
    transform = d: toStoreMaybe (deps-unpack.unpackMaybe d);

in builtins.map transform (builtins.attrValues all)

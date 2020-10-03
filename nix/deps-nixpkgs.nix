{ lib
, deps-set
}:

prev:

{ nixExpr
, location
}:


let

    foundExprs =
        if lib.isDerivation nixExpr
        then [ nixExpr ]
        else if builtins.typeOf nixExpr == "list"
        then nixExpr
        else if builtins.typeOf nixExpr == "set"
        then builtins.attrValues nixExpr
        else [];

    foundDrvs = lib.filter lib.isDerivation foundExprs;

    drvList =
        if foundDrvs == []
        then throw "ERROR: sorry, no derivations found at ${location}"
        else foundDrvs;

    allDrvs = seen: worklist:
        let h = builtins.head worklist;
            t = builtins.tail worklist;
            nextSeen =
                if deps-set.has h seen
                then seen
                else deps-set.insert h seen;
            onlyWorthFollowing = builtins.filter (d:
                lib.isDerivation d
                && d ? isHaskellLibrary
                && ! deps-set.has d nextSeen);
            nextWork = onlyWorthFollowing h.getBuildInputs.haskellBuildInputs;
        in
        if worklist == []
        then seen
        else allDrvs nextSeen (nextWork ++ t);

    hasGhc = p: p ? compiler;

    ghc =
        let addGhc = p: acc: acc // { ghc = p.compiler; };
        in lib.foldr addGhc {} (builtins.filter hasGhc drvList);

in {
    initial = prev.initial // deps-set.fromList drvList;
    all = allDrvs prev.all drvList;
    ghc = ghc // prev.ghc;
}

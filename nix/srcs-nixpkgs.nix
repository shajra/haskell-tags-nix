{ lib
, set
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
                if set.has h seen
                then seen
                else set.insert h seen;
            onlyWorthFollowing = builtins.filter (d:
                lib.isDerivation d
                && (d ? isHaskellLibrary || d ? haskellCompilerName)
                && ! set.has d nextSeen);
            nextWork = onlyWorthFollowing
                (h.buildInputs
                    ++ h.nativeBuildInputs
                    ++ h.propagatedBuildInputs
                    ++ h.propagatedNativeBuildInputs);
        in
        if worklist == []
        then seen
        else allDrvs nextSeen (nextWork ++ t);

in {
    initial = prev.initial // set.fromList drvList;
    all = allDrvs prev.all drvList;
}

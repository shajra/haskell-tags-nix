{ set }:

prev:

{ nixExpr
, location
}:

let

    isPackage = p:
        p ? project && p.project ? hsPkgs
        && p ? isHaskell && p.isHaskell
        && (builtins.tryEval p.src).success;

    foundExprs =
        if isPackage nixExpr
        then [ nixExpr ]
        else if builtins.typeOf nixExpr == "list"
        then nixExpr
        else if builtins.typeOf nixExpr == "set"
        then builtins.attrValues nixExpr
        else [];

    foundPkgs = builtins.filter isPackage foundExprs;

    pkgsList =
        if foundPkgs == []
        then throw "ERROR: sorry, no Haskell.nix packages found at ${location}"
        else foundPkgs;

    all = set.fromList
        (builtins.filter isPackage
            (builtins.concatMap
                (p: builtins.attrValues p.project.hsPkgs)
                pkgsList));

in {
    initial = prev.initial // set.fromList pkgsList;
    all = prev.all // all;
}

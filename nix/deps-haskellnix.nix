{ lib, deps-set }:

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

    # IDEA: technically, this approach grabs more packages than is strictly
    # needed for the initial target package.  We're just grabing everything
    # needed by the Haskell.nix build for the project.  This is not explained in
    # the documentation.  Maybe after noodling in a `nix repl` session it may be
    # more clear if there's a better way to packages recursively the way done in
    # `deps-nixpkgs.nix`.
    #
    all = deps-set.fromList
        (builtins.filter isPackage
            (builtins.concatMap
                (p: builtins.attrValues p.project.hsPkgs)
                pkgsList));

    hasGhc = p:
        p ? project
        && p.project ? pkg-set
        && p.project.pkg-set ? config
        && p.project.pkg-set.config ? ghc
        && p.project.pkg-set.config.ghc ? package;

    ghc =
        let addGhc = p: acc:
                acc // { ghc = p.project.pkg-set.config.ghc.package; };
        in lib.foldr addGhc {} (builtins.filter hasGhc pkgsList);

in {
    initial = prev.initial // deps-set.fromList pkgsList;
    all = prev.all // all;
    ghc = ghc // prev.ghc;
}

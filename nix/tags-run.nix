{ lib
, nix-haskell-tags-lib
}:

{ attrPaths ? []
, nixFile
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

    splitAttrPaths = builtins.map (lib.splitString ".") attrPaths;

    importMaybe = f: if builtins.typeOf f == "path" then import f else f;

    callMaybe = e: if builtins.typeOf e == "lambda" then e {} else e;

    selection = e: p:
        let location = builtins.concatStringsSep "." p;
            nixExpr = lib.attrByPath p [] e;
        in { inherit nixExpr location; };

    selectMaybe = e: ps:
        if ps == []
        then [{ nixExpr = e; location = "(no attr selection)"; }]
        else builtins.map (selection e) ps;

    annotatedNixExprs =
        selectMaybe (callMaybe (importMaybe nixFile)) splitAttrPaths;

in nix-haskell-tags-lib {
    inherit
    emacs
    haskellNix
    includeAll
    exclude
    followSymlinks
    noModuleTags
    qualified
    fullyQualified
    srcPrefix
    annotatedNixExprs;
}

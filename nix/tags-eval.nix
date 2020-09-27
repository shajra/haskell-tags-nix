{ nix-haskell-tags-lib
}:

{ nixExprs
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

    annotate = e: { nixExpr = e; location = "(no attr selection)"; };

    annotatedNixExprs = builtins.map annotate nixExprs;

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

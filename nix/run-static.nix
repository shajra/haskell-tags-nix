{ args
, lib
, tags-static
}:

{ nixFile
, attrPaths ? []
, exprArg ? {}
, haskellNix ? false
, emacs ? false
, includeGhc ? false
, includeTargets ? false
, exclude ? []
, followSymlinks ? false
, noModuleTags ? false
, qualified ? false
, fullyQualified ? false
, srcPrefix ? ""
}:

let

    annotatedNixExprs = args.readNixFile nixFile attrPaths exprArg;

    fasttagsArgs = args.fasttagsArgs {
        inherit
        emacs
        exclude
        followSymlinks
        noModuleTags
        qualified
        fullyQualified
        srcPrefix;
    };

in tags-static {
    inherit
    annotatedNixExprs
    haskellNix
    includeGhc
    includeTargets
    fasttagsArgs;
}

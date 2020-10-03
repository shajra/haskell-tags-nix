{ args
, tags-static
}:

{ nixExprs
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

    annotatedNixExprs = args.readNixExprs nixExprs;

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

{ args
, lib
, tags-static
}:

{ nixFile
, attrPaths ? []
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

    annotatedNixExprs = args.readNixFile nixFile attrPaths;

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

{ args
, tags-dynamic
}:

{ nixExprs
, tagsStaticPath ? if emacs then "TAGS" else "tags"
, tagsDynamicPath ? if emacs then "TAGS.local" else "tags"
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

in tags-dynamic {
    inherit
    annotatedNixExprs
    haskellNix
    includeGhc
    includeTargets
    tagsStaticPath
    tagsDynamicPath
    fasttagsArgs;
}

{ args
, lib
, tags-dynamic
}:

{ nixFile
, tagsStaticPath ? if emacs then "TAGS" else "tags"
, tagsDynamicPath ? if emacs then "TAGS.local" else "tags"
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

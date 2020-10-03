{ lib
, writeTextFile
}:

let fasttagsArgs =
        { emacs
        , exclude
        , followSymlinks
        , noModuleTags
        , qualified
        , fullyQualified
        , srcPrefix
        }: {
            emacs = if emacs then "--emacs" else "";
            exclude =
                let toArg = e: "--exclude='${e}'";
                in lib.concatStringsSep " " (builtins.map toArg exclude);
            followSymlinks = if followSymlinks then "--follow-symlinks" else "";
            noModuleTags = if noModuleTags then "--no-module-tags" else "";
            qualified = if qualified then "--qualified" else "";
            fullyQualified = if fullyQualified then "--fully-qualified" else "";
            srcPrefix = if srcPrefix == "" then "" else "--src-prefix='${srcPrefix}'";
        };

    emptyAnnotated = e: { nixExpr = e; location = "(no attr selection)"; };

    readNixExprs = nixExprs: builtins.map emptyAnnotated nixExprs;

    splitAttrPaths = builtins.map (lib.splitString ".");

    importMaybe = f: if builtins.typeOf f == "path" then import f else f;

    callMaybe = e: if builtins.typeOf e == "lambda" then e {} else e;

    selection = e: p:
        let location = builtins.concatStringsSep "." p;
            nixExpr = lib.attrByPath p [] e;
        in { inherit nixExpr location; };

    selectMaybe = e: ps:
        if ps == [] then [emptyAnnotated e] else builtins.map (selection e) ps;

    readNixFile = nixFile: attrPaths:
        selectMaybe (callMaybe (importMaybe nixFile))
            (splitAttrPaths attrPaths);

    fasttagsSrcs = srcs:
        let depStr = lib.concatStrings (builtins.map (s: s + "\n") srcs);
        in writeTextFile { name = "tags-deps"; text = "${depStr}"; };

in {
    inherit
    readNixExprs
    readNixFile
    fasttagsArgs
    fasttagsSrcs;
}

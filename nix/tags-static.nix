{ args
, deps-srcs
, findutils
, haskellPackages
, stdenv
}:

{ annotatedNixExprs
, haskellNix
, includeGhc
, includeTargets
, fasttagsArgs
}:

let

    depSrcs = deps-srcs {
        static = true;
        inherit
        annotatedNixExprs
        haskellNix
        includeGhc
        includeTargets;
    };

in stdenv.mkDerivation {
    name = "tags";
    phases = [ "installPhase" ];
    nativeBuildInputs = [ findutils haskellPackages.fast-tags ];
    installPhase = ''
        srcs_file="${args.fasttagsSrcs depSrcs}"
        echo
        echo "SOURCES in $srcs_file:"
        while read -r f
        do echo "- $f"
        done < "$srcs_file"
        echo RUNNING: xargs echo fast-tags -R -o "$out" \
            ${fasttagsArgs.emacs} \
            ${fasttagsArgs.exclude} \
            ${fasttagsArgs.followSymlinks} \
            ${fasttagsArgs.noModuleTags} \
            ${fasttagsArgs.qualified} \
            ${fasttagsArgs.fullyQualified} \
            ${fasttagsArgs.srcPrefix} \
            \< "$srcs_file"
        xargs fast-tags -R -o "$out" \
            ${fasttagsArgs.emacs} \
            ${fasttagsArgs.exclude} \
            ${fasttagsArgs.followSymlinks} \
            ${fasttagsArgs.noModuleTags} \
            ${fasttagsArgs.qualified} \
            ${fasttagsArgs.fullyQualified} \
            ${fasttagsArgs.srcPrefix} \
            < "$srcs_file"
        if ! [ -f "$out" ]
        then
            echo "ERROR: no Haskell source found to tag" >&2
            exit 1
        fi
    '';
}

{ args
, coreutils
, deps-srcs
, findutils
, haskellPackages
, lib
, nix-project-lib
}:

{ annotatedNixExprs
, haskellNix
, includeGhc
, includeTargets
, tagsStaticPath
, tagsDynamicPath
, fasttagsArgs
}:

let

    depSrcs = deps-srcs {
        static = false;
        inherit
        annotatedNixExprs
        haskellNix
        includeGhc
        includeTargets;
    };

    prog_name = "nix-haskell-tags-generate";
    desc = "Generate ctags/etags for a specific project";
    onlyInStore = lib.hasPrefix builtins.storeDir;
    splitSrcs = lib.partition onlyInStore depSrcs;
    storeSrcs = args.fasttagsSrcs splitSrcs.right;
    localSrcs = args.fasttagsSrcs splitSrcs.wrong;

in nix-project-lib.writeShellChecked prog_name desc
''
set -eu
set -o pipefail


. "${nix-project-lib.lib-sh}/bin/lib.sh"


ALL=false
TAGS_STATIC_PATH="${builtins.toString tagsStaticPath}"
TAGS_DYNAMIC_PATH="${builtins.toString tagsDynamicPath}"


print_usage()
{
    "${coreutils}/bin/cat" - <<EOF
USAGE: ${prog_name} [OPTION]...

DESCRIPTION:

    ${desc}

OPTIONS:

    -h --help  print this help message
    -a --all   regenerate all tags, not just local projects

EOF
}

main()
{
    parse_args "$@"
    if "$ALL"
    then make_tags "${storeSrcs}" "$TAGS_STATIC_PATH"
    fi
    make_tags "${localSrcs}" "$TAGS_DYNAMIC_PATH"
}

parse_args()
{
    while ! [ "''${1:-}" = "" ]
    do
        case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -a|--all)
            ALL=true
            ;;
        *)
            die "'$1' not recognized"
            ;;
        esac
        shift
    done
}

make_tags()
{
    local srcs_file="$1"
    local tags_path="$2"

    echo
    echo "SOURCES in $srcs_file:"
    while read -r f
    do echo "- $f"
    done < "$srcs_file"
    echo RUNNING: "${findutils}/bin/xargs" \
        "${haskellPackages.fast-tags}/bin/fast-tags" -R -o "$tags_path" \
        ${fasttagsArgs.emacs} \
        ${fasttagsArgs.exclude} \
        ${fasttagsArgs.followSymlinks} \
        ${fasttagsArgs.noModuleTags} \
        ${fasttagsArgs.qualified} \
        ${fasttagsArgs.fullyQualified} \
        ${fasttagsArgs.srcPrefix} \
        \< "$srcs_file"
    "${findutils}/bin/xargs" \
        "${haskellPackages.fast-tags}/bin/fast-tags" -R -o "$tags_path" \
        ${fasttagsArgs.emacs} \
        ${fasttagsArgs.exclude} \
        ${fasttagsArgs.followSymlinks} \
        ${fasttagsArgs.noModuleTags} \
        ${fasttagsArgs.qualified} \
        ${fasttagsArgs.fullyQualified} \
        ${fasttagsArgs.srcPrefix} \
        < "$srcs_file"
}


main "$@"
''

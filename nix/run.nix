{ coreutils
, lib
, nix-project-lib
}:

let
    progName = "haskell-tags-nix";
    meta.description = "Generate ctags/etags file from a Nix expression";
    src = lib.sourceFilesBySuffices ./. [".nix" ".json"];
in

nix-project-lib.writeShellCheckedExe progName
{
    inherit meta;
    pathPure = false;
    path = [ coreutils ];
}
''
set -eu
set -o pipefail


. "${nix-project-lib.common}/share/nix-project/common.bash"


NIX_EXE="$(command -v nix || true)"
ARGS=(--print-build-logs --show-trace --file "${src}" --arg nixFile ./.)
EMACS=false
STATIC=false
WORK_DIR="$(pwd)"
ATTR_PATHS=()
ATTR_ARGS=()
EXCLUDE=()
TAGS_STATIC_PATH=
TAGS_DYNAMIC_PATH=
SCRIPT_PATH=run/tags-generate
SKIP_REBUILD=false


print_usage()
{
    cat - <<EOF
USAGE: ${progName} [OPTION]...

DESCRIPTION:

    ${meta.description}

OPTIONS:

    -h --help               print this help message

    -w --work-dir PATH      directory to use as a working directory
    -f --file PATH          Nix expression of filepath to import
    -A --attr PATH          attr path to target derivations, multiple allowed
       --arg NAME VALUE     argument to pass Nix expression if it's a function

    -o --output PATH        file for tags to source within /nix/store
    -O --output-local PATH  file for tags to source outside /nix/store
    -s --static             all source in /nix/store, no generation script
    -l --script-link PATH   where to link tags generation script (ignored for -s)
    -L --no-script-link     don't make a script link
    -S --skip-rebuild       skip rebuilding script and tags within /nix/store
                            (unneeded for -s)

    -H --haskell-nix        interpret input as Haskell.nix package
    -e --emacs              generate tags in Emacs format (otherwise Vi)

    -g --include-ghc        include tag references from GHC source
    -t --include-targets    include targets as well as their dependencies
    -a --all                same as -g -t

    -x --exclude PATTERN    filepaths to exclude (multiple allowed)
    -F --folow-symlinks     follow symlinks
    -T --no-module-tags     do not generate tags for modules
    -q --qualified          qualified with one level of module (M.f)
    -Q --fully-qualified    fully qualified (A.B.C.f)
    -p --src-prefix PATH    path to strip from module names

    -N --nix PATH           filepath of 'nix' executable to use

EOF
}

main()
{
    parse_args "$@"
    ARGS+=(--arg attrPaths "[ ''${ATTR_PATHS[*]} ]")
    ARGS+=(--arg exprArg "{ ''${ATTR_ARGS[*]} }")
    ARGS+=(--arg exclude "[ ''${EXCLUDE[*]} ]")
    add_nix_to_path "$NIX_EXE"
    cd "$WORK_DIR"
    if "$STATIC"
    then
        prep_path "$(tags_static_path)"
        link_static_tags
    else
        ARGS+=(--argstr tagsStaticPath "$(tags_static_path)")
        ARGS+=(--argstr tagsDynamicPath "$(tags_dynamic_path)")
        link_script_maybe
        run_script
    fi
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
        -w|--work-dir)
            if ! [ -d "''${2:-}" ]
            then die "'$1' requires a directory as an argument"
            fi
            WORK_DIR="''${2:-}"
            shift
            ;;
        -f|--file)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            ARGS+=(--arg nixFile "''${2:-}")
            shift
            ;;
        -A|--attr)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            ATTR_PATHS+=("\"''${2:-}\"")
            shift
            ;;
        --arg)
            if [ -z "''${2:-}" ] || [ -z "''${3:-}" ]
            then die "'$1' requires two arguments"
            fi
            ATTR_ARGS+=("''${2:-} = ''${3:-};")
            shift 2
            ;;
        -o|--output)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            TAGS_STATIC_PATH="''${2:-}"
            shift
            ;;
        -O|--output-local)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            TAGS_DYNAMIC_PATH="''${2:-}"
            shift
            ;;
        -s|--static)
            STATIC=true
            ;;
        -l|--script-link)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            SCRIPT_PATH="''${2:-}"
            shift
            ;;
        -L|--no-script-link)
            SCRIPT_PATH=
            ;;
        -S|--skip-rebuild)
            SKIP_REBUILD=true
            ;;
        -H|--haskell-nix)
            ARGS+=(--arg haskellNix true)
            ;;
        -e|--emacs)
            EMACS=true
            ARGS+=(--arg emacs true)
            ;;
        -g|--include-ghc)
            ARGS+=(--arg includeGhc true)
            ;;
        -t|--include-targets)
            ARGS+=(--arg includeTargets true)
            ;;
        -a|--all)
            ARGS+=(--arg includeGhc true)
            ARGS+=(--arg includeTargets true)
            ;;
        -x|--exclude)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            EXCLUDE+=("\"''${2:-}\"")
            shift
            ;;
        -F|--folow-symlinks)
            ARGS+=(--arg followSymlinks true)
            ;;
        -T|--no-module-tags)
            ARGS+=(--arg noModuleTags true)
            ;;
        -q|--qualified)
            ARGS+=(--arg qualified true)
            ;;
        -Q|--fully-qualified)
            ARGS+=(--arg fullyQualified true)
            ;;
        -p|--src-prefix)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            ARGS+=(--argstr srcPrefix "''${2:-}")
            shift
            ;;
        -N|--nix)
            if [ -z "''${2:-}" ]
            then die "'$1' requires argument"
            fi
            NIX_EXE="''${2:-}"
            shift
            ;;
        *)
            die "'$1' not recognized"
            ;;
        esac
        shift
    done
}

link_static_tags()
{
    nix build \
        --out-link "$(tags_static_path)" \
        build.run-static \
        "''${ARGS[@]}"
}

link_script_maybe()
{
    if [ -x "$SCRIPT_PATH" ] && "$SKIP_REBUILD"
    then
        echo "USING PRE-EXISTING SCRIPT: $SCRIPT_PATH ->"
        echo "    $(readlink -f "$SCRIPT_PATH")"
    else
        nix build --no-link "''${ARGS[@]}" build.run-dynamic >/dev/null
        local out; out="$(nix path-info "''${ARGS[@]}" build.run-dynamic)"
        local script="$out/bin/haskell-tags-nix-generate"
        if [ -n "$SCRIPT_PATH" ]
        then
            echo "LINKING SCRIPT: $script ->"
            prep_path "$SCRIPT_PATH"
            printf "    "
            nix-store --add-root "$SCRIPT_PATH" --indirect --realize "$script"
            ln --symbolic --no-target-directory --force "$script" "$SCRIPT_PATH"
        else
            echo "NOT LINKING SCRIPT: $script"
        fi
    fi
}

run_script()
{
    local switches=("--all")
    if [ -f "$(tags_static_path)" ] && "$SKIP_REBUILD"
    then switches=()
    fi
    if [ -x "$SCRIPT_PATH" ]
    then "$SCRIPT_PATH" "''${switches[@]}"
    else nix run \
        --ignore-environment \
        "''${ARGS[@]}" \
        build.run-dynamic \
        --command haskell-tags-nix-generate "''${switches[@]}"
    fi
}

tags_static_path()
{
    if [ -n "$TAGS_STATIC_PATH" ]
    then echo "$TAGS_STATIC_PATH"
    elif "$EMACS"
    then echo TAGS
    else echo tags
    fi
}

tags_dynamic_path()
{
    if [ -n "$TAGS_DYNAMIC_PATH" ]
    then echo "$TAGS_DYNAMIC_PATH"
    elif "$EMACS"
    then echo TAGS.local
    else echo tags
    fi
}

prep_path()
{
    local parent; parent="$(dirname "$1")"
    mkdir --parents "$parent"
}


main "$@"
''

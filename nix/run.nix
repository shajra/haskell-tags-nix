{ coreutils
, lib
, nix-project-lib
}:

let
    prog_name = "nix-haskell-tags";
    desc = "Generate ctags/etags file from a Nix expression";
    src = lib.sourceFilesBySuffices ./. [".nix" ".json"];
in

nix-project-lib.writeShellChecked prog_name desc
''
set -eu
set -o pipefail


. "${nix-project-lib.lib-sh}/bin/lib.sh"


NIX_EXE="$(command -v nix || true)"
ARGS=(--print-build-logs --show-trace --file "${src}" --arg nixFile ./.)
EMACS=false
STATIC=false
WORK_DIR="$(pwd)"
ATTR_PATHS=()
EXCLUDE=()
TAGS_STATIC_PATH=
TAGS_DYNAMIC_PATH=
SCRIPT_PATH=run/tags-generate
SKIP_REBUILD=false


print_usage()
{
    "${coreutils}/bin/cat" - <<EOF
USAGE: ${prog_name} [OPTION]...

DESCRIPTION:

    ${desc}

OPTIONS:

    -h --help               print this help message

    -w --work-dir PATH      directory to use as a working directory
    -f --file PATH          Nix expression of filepath to import
    -A --attr PATH          attr path to target derivations, multiple allowed

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
            local work_dir="''${2:-}"
            if ! [ -d "$work_dir" ]
            then die "'$1' requires a directory as an argument"
            fi
            WORK_DIR="$work_dir"
            shift
            ;;
        -f|--file)
            local nix_file="''${2:-}"
            if [ -z "$nix_file" ]
            then die "'$1' requires argument"
            fi
            ARGS+=(--arg nixFile "$nix_file")
            shift
            ;;
        -A|--attr)
            local attr_path="''${2:-}"
            if [ -z "$attr_path" ]
            then die "'$1' requires argument"
            fi
            ATTR_PATHS+=("\"$attr_path\"")
            shift
            ;;
        -o|--output)
            local path="''${2:-}"
            if [ -z "$path" ]
            then die "'$1' requires argument"
            fi
            TAGS_STATIC_PATH="$path"
            shift
            ;;
        -O|--output-local)
            local path="''${2:-}"
            if [ -z "$path" ]
            then die "'$1' requires argument"
            fi
            TAGS_DYNAMIC_PATH="$path"
            shift
            ;;
        -s|--static)
            STATIC=true
            ;;
        -l|--script-link)
            local script_path="''${2:-}"
            if [ -z "$script_path" ]
            then die "'$1' requires argument"
            fi
            SCRIPT_PATH="$script_path"
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
            local exclude="''${2:-}"
            if [ -z "$exclude" ]
            then die "'$1' requires argument"
            fi
            EXCLUDE+=("\"$exclude\"")
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
            local prefix="''${2:-}"
            if [ -z "$prefix" ]
            then die "'$1' requires argument"
            fi
            ARGS+=(--argstr srcPrefix "$prefix")
            shift
            ;;
        -N|--nix)
            NIX_EXE="''${2:-}"
            if [ -z "$NIX_EXE" ]
            then die "'$1' requires argument"
            fi
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
        run-static \
        "''${ARGS[@]}"
}

link_script_maybe()
{
    if [ -x "$SCRIPT_PATH" ] && "$SKIP_REBUILD"
    then
        echo "USING PRE-EXISTING SCRIPT: $SCRIPT_PATH ->"
        echo "    $("${coreutils}/bin/readlink" -f "$SCRIPT_PATH")"
    else
        nix build --no-link "''${ARGS[@]}" run-dynamic >/dev/null
        local out; out="$(nix path-info "''${ARGS[@]}" run-dynamic)"
        local script="$out/bin/nix-haskell-tags-generate"
        if [ -n "$SCRIPT_PATH" ]
        then
            echo "LINKING SCRIPT: $script ->"
            prep_path "$SCRIPT_PATH"
            printf "    "
            nix-store --add-root "$SCRIPT_PATH" --indirect --realize "$script"
            "${coreutils}/bin/ln" \
                --symbolic --no-target-directory --force "$script" "$SCRIPT_PATH"
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
        run-dynamic \
        --command nix-haskell-tags-generate "''${switches[@]}"
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
    local parent; parent="$("${coreutils}/bin/dirname" "$1")"
    "${coreutils}/bin/mkdir" --parents "$parent"
}


main "$@"
''

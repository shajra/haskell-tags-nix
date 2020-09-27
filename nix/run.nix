{ coreutils
, nix-project-lib
}:

let
    prog_name = "nix-haskell-tags";
    desc = "Generate ctags/etags file from a Nix expression";
in

nix-project-lib.writeShellChecked prog_name desc
''
set -eu
set -o pipefail


. "${nix-project-lib.lib-sh}/bin/lib.sh"


NIX_EXE="$(command -v nix || true)"
ARGS=(--print-build-logs --show-trace build --file "${./.}")
EMACS=false
ATTR_PATHS=()
OUT_LINK=


print_usage()
{
    ${coreutils}/bin/cat - <<EOF
USAGE: ${prog_name} [OPTION] COMMAND

DESCRIPTION:

    ${desc}

OPTIONS:

    -h --help             print this help messagee
    -H --haskell-nix      interpret as Haskell.nix package
    -a --all              don't exclude input derivations
    -o --out-link PATH    where to output tags file
    -f --file PATH        Nix expression of filepath to import
    -A --attr PATH        attr path to input derivations, multiple allowed
    -e --emacs            generate tags in Emacs format (otherwise Vi)
    -x --exclude PATTERN  filepaths to exclude
    -L --folow-symlinks   follow symlinks
    -T --no-module-tags   do not generate tags for modules
    -q --qualified        qualified with one level of module (M.f)
    -Q --fully-qualified  fully qualified (A.B.C.f)
    -p --src-prefix PATH  path to strip from module names
    -N --nix PATH         filepath of 'nix' executable to use

EOF
}

main()
{
    parse_args "$@"
    add_nix_to_path "$NIX_EXE"
    ARGS+=(--out-link "$(out_link)")
    ARGS+=(--arg attrPaths "[ ''${ATTR_PATHS[@]} ]")
    ARGS+=(nix-haskell-tags-run)
    nix "''${ARGS[@]}"
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
        -H|--haskell-nix)
            ARGS+=(--arg haskellNix true)
            ;;
        -a|--all)
            ARGS+=(--arg includeAll true)
            ;;
        -o|--out-link)
            local out_link="''${2:-}"
            if [ -z "$out_link" ]
            then die "'$1' requires argument"
            fi
            OUT_LINK="$out_link"
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
        -N|--nix)
            NIX_EXE="''${2:-}"
            if [ -z "$NIX_EXE" ]
            then die "'$1' requires argument"
            fi
            shift
            ;;
        -e|--emacs)
            EMACS=true
            ARGS+=(--arg emacs true)
            ;;
        -x|--exclude)
            local exclude="''${2:-}"
            if [ -z "$exclude" ]
            then die "'$1' requires argument"
            fi
            ARGS+=(--argstr exclude "$exclude")
            shift
            ;;
        -L|--folow-symlinks)
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
        *)
            die "'$1' not recognized"
            ;;
        esac
        shift
    done
}

out_link()
{
    if [ -n "$OUT_LINK" ]
    then echo "$OUT_LINK"
    elif "$EMACS"
    then echo TAGS
    else echo tags
    fi
}

main "$@"
''

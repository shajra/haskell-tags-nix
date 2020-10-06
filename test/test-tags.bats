HEADER="$BUILD_NAME: $INCLUDE_GHC_NAME: $INCLUDE_TARGETS_NAME: $FORMAT_NAME"

@test "$HEADER: includes/excludes ghc" {
    if "$INCLUDE_GHC_VALUE"
    then grep --extended-regexp '/nix/store/.*-ghc-' "$out"
    else grep --invert-match --extended-regexp '/nix/store/.*-ghc-' "$out"
    fi
}

@test "$HEADER: includes/excludes putStrLn" {
    if "$INCLUDE_GHC_VALUE"
    then grep --extended-regexp '\bputStrLn\b' "$out"
    else grep --invert-match --extended-regexp '\bputStrLn\b' "$out"
    fi
}

@test "$HEADER: includes void" {
    grep '/nix/store/.*-void-' "$out"
}

@test "$HEADER: includes/excludes example project" {
    if "$INCLUDE_TARGETS_VALUE"
    then grep --extended-regexp '\bexampleMsg\b' "$out"
    else grep --invert-match --extended-regexp '\bexampleMsg\b' "$out"
    fi
}

@test "$BUILD_TYPE: $EMACS: GHC=$INCLUDE_GHC: TARGET=$INCLUDE_TARGET: includes/excludes ghc" {
    if "$INCLUDE_GHC"
    then grep --extended-regexp '/nix/store/.*-ghc-' "$out"
    else grep --invert-match --extended-regexp '/nix/store/.*-ghc-' "$out"
    fi
}

@test "$BUILD_TYPE: $EMACS: GHC=$INCLUDE_GHC: TARGET=$INCLUDE_TARGET: includes putStrLn" {
    if "$INCLUDE_GHC"
    then grep --extended-regexp '\bputStrLn\b' "$out"
    else grep --invert-match --extended-regexp '\bputStrLn\b' "$out"
    fi
}

@test "$BUILD_TYPE: $EMACS: GHC=$INCLUDE_GHC: TARGET=$INCLUDE_TARGET: includes void" {
    grep '/nix/store/.*-void-' "$out"
}

@test "$BUILD_TYPE: $EMACS: GHC=$INCLUDE_GHC: TARGET=$INCLUDE_TARGET: includes/excludes example project" {
    if "$INCLUDE_TARGET"
    then grep --extended-regexp '\bexampleMsg\b' "$out"
    else grep --invert-match --extended-regexp '\bexampleMsg\b' "$out"
    fi
}

@test "$BUILD_TYPE: INCLUDE_ALL=$INCLUDE_ALL: includes ghc" {
    grep '/nix/store/.*-ghc-' "$out"
}

@test "$BUILD_TYPE: INCLUDE_ALL=$INCLUDE_ALL: includes putStrLn" {
    grep --extended-regexp '\bputStrLn\b' "$out"
}

@test "$BUILD_TYPE: INCLUDE_ALL=$INCLUDE_ALL: includes void" {
    grep '/nix/store/.*-void-' "$out"
}

@test "$BUILD_TYPE: INCLUDE_ALL=$INCLUDE_ALL: includes/excludes example project" {
    if "$INCLUDE_ALL"
    then grep --extended-regexp '\bexampleMsg\b' "$out"
    else grep --invert-match --extended-regexp '\bexampleMsg\b' "$out"
    fi
}

versionToPreprocessor() {
    local VERSION=$1
    local PREPROCESSOR_VERSION=""
    
    IFS='.' read -r -A VERSION_TUPLE <<< "$VERSION"

    while [[ ${#VERSION_TUPLE[@]} -lt 3 ]]; do
        VERSION_TUPLE+=("00")
    done

    for component in "${VERSION_TUPLE[@]}"; do
        PREPROCESSOR_VERSION+=$(printf %02d $component)
    done
    printf $PREPROCESSOR_VERSION
}
# Variables that MUST be set:
# WORKON_GO_VERSION => The version of Go to be used for the profile.

function __util_activate {
    [[ -z "$WORKON_GO_VERSION" ]] && return
    export gocmd="go$WORKON_GO_VERSION"
    if ! command -v "$gocmd" &> /dev/null; then
        echo "Installing $gocmd..."
        GOPROXY="" go install golang.org/dl/$gocmd@latest || return
    fi
    if ! $gocmd version &> /dev/null; then
        echo "Downloading $gocmd..."
        $gocmd download || return
    fi
    alias go="$gocmd"
}

function __util_clean {
    if [[ ! -z "$(alias | grep "^alias go")" ]]; then
        unalias go
    fi
    unset WORKON_GO_VERSION
}

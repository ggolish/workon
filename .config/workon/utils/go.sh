# Variables that MUST be set:
# WORKON_GO_VERSION => The version of Go to be used for the profile.

function __util_activate {

    function ensure {
        if ! command -v "$1" >/dev/null 2>&1; then
            echo "$1 not found, installing..."
            $2 $1
        fi
    }

    function install_restish {
        go install github.com/danielgtaylor/restish@latest
    }

    function install_gocmd {
        GOPROXY="" go install golang.org/dl/$1@latest
    }

    [[ -z "$WORKON_GO_VERSION" ]] && return

    local gocmd=""
    if [[ "$WORKON_GO_VERSION" == "stable" ]]; then
        ensure restish install_restish
        gocmd=$(restish https://go.dev/dl/?mode=json -f "body[0].version" -r)
    else
        gocmd="go$WORKON_GO_VERSION"
    fi

    ensure $gocmd install_gocmd

    if ! $gocmd version &> /dev/null; then
        echo "Downloading $gocmd..."
        $gocmd download
    fi

    alias go="$gocmd"

    unset ensure
    unset install_restish
    unset install_gocmd
}

function __util_clean {
    if [[ ! -z "$(alias | grep "^alias go")" ]]; then
        unalias go
    fi
    unset WORKON_GO_VERSION
}

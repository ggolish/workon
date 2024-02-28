# Variables that MUST be set:
#   WORKON_GO_VERSION => The version of Go to be used for the profile. "stable"
#   can be provided to select the latest release.
#
# Variables used internally:
#   WORKON_GO_DIR: The local go installation directory used to manage versions.

function __util_activate {
    [[ -z "$WORKON_GO_VERSION" ]] && return
    WORKON_GO_DIR="$HOME/.local/go"
    mkdir -p "$WORKON_GO_DIR"

    local go_version="go${WORKON_GO_VERSION}"
    if [[ "$WORKON_GO_VERSION" == "stable" ]]; then
        go_version=$(curl https://go.dev/dl/?mode=json 2> /dev/null | jq -rc .[0].version)
    fi

    local dest_path="${WORKON_GO_DIR}/${go_version}"
    if [[ ! -d "$dest_path" ]]; then
        echo "Fetching new Go version ${go_version}..."
        mkdir -p "$dest_path"
        local go_archive="${go_version}.linux-amd64.tar.gz"
        local go_url="https://go.dev/dl/${go_archive}"
        pushd /tmp
        wget "$go_url" &&
            tar -xvzf "$go_archive" -C "$dest_path"
        popd
        echo "Done"
    fi

    export PATH="${dest_path}/go/bin:$PATH"
    OLD_GOROOT="$GOROOT"
    export GOROOT="${dest_path}/go"
}

function __util_clean {
    [[ -z "$WORKON_GO_VERSION" ]] && return
    local paths="$(echo -n "$PATH" | tr ':' '\n' | grep -v "^$WORKON_GO_DIR")"
    local newpath=""
    for path in $paths; do
        newpath="$newpath:$path"
    done
    export PATH="$newpath"

    export GOROOT="$OLD_GOROOT"
    unset OLD_GOROOT

    unset WORKON_GO_VERSION
    unset WORKON_GO_DIR
}

# Variables that MUST be set:
#   WORKON_FLUTTER_VERSION: The version of flutter to use. It will downloaded
#   automatically if it is not present. The keywords 'stable' and 'beta' can be
#   used to indicate the latest build in those channels should be used.
#
# Variables used internally:
#   WORKON_FLUTTER_DIR: The local flutter installation directory used to manage versions.


function __util_activate {
    [[ -z "$WORKON_FLUTTER_VERSION" ]] && return

    WORKON_FLUTTER_DIR="$HOME/.local/flutter"
    mkdir -p "$WORKON_FLUTTER_DIR"

    function __flutter_get_version_by_channel {
        local channel="$1"
        [[ "$channel" != "stable" ]] && [[ "$channel" != "beta" ]] && echo "invalid flutter channel $channel" 1>&2 && return
        local versions=$(curl https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json 2> /dev/null)
        local hash=$(echo -n "$versions" | jq -r .current_release."$channel")
        echo -n "$versions" | jq -r ".releases | .[] | select(.hash == \"$hash\") | .version"
    }

    function __flutter_get_version {
        local version="$1"

        if [[ "$version" == "stable" || "$version" == "beta" ]]; then
            version=$(__flutter_get_version_by_channel "$version")
        fi

        # A postfix of .pre indicates a beta channel build.
        if [[ "$(basename "$version" .pre)" != "$version" ]]; then
            printf "https://storage.googleapis.com/flutter_infra_release/releases/beta/linux/flutter_linux_%s-beta.tar.xz" "$version"
            return
        fi

        printf "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_%s-stable.tar.xz" "$version"
    }

    function __flutter_sanatize_path {
        local paths="$(echo -n "$PATH" | tr ':' '\n' | grep -v "^$WORKON_FLUTTER_DIR")"
        local newpath=""
        for path in $paths; do
            newpath="$newpath:$path"
        done
        export PATH="$newpath"
    }

    local url="$(__flutter_get_version "$WORKON_FLUTTER_VERSION")"
    local flutterarchive="$(basename "$url")"
    local flutterdir="$(basename "$url" .tar.xz)"
    local flutterdest="$WORKON_FLUTTER_DIR/$flutterdir"

    if [[ ! -d "$flutterdest" ]]; then
        pushd /tmp
        wget "$url"
        rm -rf flutter
        tar -xf "$flutterarchive"
        mv "flutter" "$flutterdest"
        popd
    fi

    __flutter_sanatize_path
    export PATH="$PATH:$flutterdest/bin"
    export PUB_CACHE="$flutterdest/.pub-cache"
    export PATH="$PATH:$PUB_CACHE/bin"
}

function __util_clean {
    [[ -z "$WORKON_FLUTTER_VERSION" ]] && return

    __flutter_sanatize_path
    unset __flutter_get_version
    unset __flutter_sanatize_path

    unset WORKON_FLUTTER_DIR
    unset WORKON_FLUTTER_VERSION
    unset PUB_CACHE
}

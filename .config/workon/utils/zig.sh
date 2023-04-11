# Variables that MUST be set:
#   WORKON_ZIG_VERSION: The zig version to download. "nigthly" is keyword that
#   can be used to always use the current nightly build.
#
# Variables used internally:
#   WORKON_ZIG_DIR: The local zig installation directory used to manage versions.


function __util_activate {
    [[ -z "$WORKON_ZIG_VERSION" ]] && return

    WORKON_ZIG_DIR="$HOME/.local/zig"
    mkdir -p "$WORKON_ZIG_DIR"

    function __zig_get_nightly {
        curl https://ziglang.org/download/index.json 2> /dev/null | \
            jq -r '.master."x86_64-linux".tarball'
    }

    function __zig_get_version {
        local version="$1"
        if [[ "$version" == "nightly" ]]; then
            __zig_get_nightly
            return
        fi
        printf https://ziglang.org/download/%s/zig-linux-x86_64-%s.tar.xz \
            "$version" "$version"
    }

    function __zig_sanatize_path {
        local paths="$(echo -n "$PATH" | tr ':' '\n' | grep -v "^$WORKON_ZIG_DIR")"
        local newpath=""
        for path in $paths; do
            newpath="$newpath:$path"
        done
        export PATH="$newpath"
    }

    local url="$(__zig_get_version "$WORKON_ZIG_VERSION")"
    local zigarchive="$(basename "$url")"
    local zigdir="$(basename "$url" .tar.xz)"
    local zigdest="$WORKON_ZIG_DIR/$zigdir"

    if [[ ! -d "$zigdest" ]]; then
        pushd /tmp
        wget "$url"
        tar -xf "$zigarchive"
        mv "$zigdir" "$zigdest"
        popd
    fi

    __zig_sanatize_path
    export PATH="$PATH:$zigdest"
}

function __util_clean {
    [[ -z "$WORKON_ZIG_VERSION" ]] && return

    __zig_sanatize_path
    unset __zig_get_nightly
    unset __zig_get_version
    unset __zig_sanatize_path

    unset WORKON_ZIG_DIR
    unset WORKON_ZIG_VERSION
}

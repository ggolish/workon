function __load_globals {
    [[ ! -d "$WORKON_GLOBALS_DIR" ]] && return
    for global in $(find $WORKON_GLOBALS_DIR -iname '*.sh'); do
        source "$global"
    done
}

function __reload_global {
    local global="$1"
    [[ -z "$global" ]] && return
    local full_path="$WORKON_GLOBALS_DIR/$global.sh"
    [[ ! -e "$full_path" ]] && return
    source "$full_path"
}

function __global_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local global="$4"

    mkdir -p "$WORKON_GLOBALS_DIR"

    if (( $new == 1 )); then
        __new global "$global"
        __reload_global "$global"
        return
    fi

    if (( $remove == 1 )); then
        __remove global "$global"
        return
    fi

    if (( $edit == 1 )); then
        # Force global select before edit to allow reloading global
        if [[ -z "$global" ]]; then
            global="$(__file_select "$WORKON_GLOBALS_DIR" "select a global")"
            [[ -z "$global" ]] && return
        fi
        __edit global "$global"
        __reload_global "$global"
        return
    fi

    echo "nothing to do"
}


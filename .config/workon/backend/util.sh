function __util_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local util="$4"

    if (( $new == 1 )); then
        __new util "$util"
        return
    fi

    if (( $remove == 1 )); then
        __remove util "$util"
        return
    fi

    if (( $edit == 1 )); then
        __edit util "$util"
        return
    fi

    echo "nothing to do"
}

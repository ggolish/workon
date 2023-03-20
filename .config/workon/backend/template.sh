#!/bin/bash

function __template_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local template="$4"

    if (( $new == 1 )); then
        __new template "$template"
        return
    fi

    if (( $remove == 1 )); then
        __remove template "$template"
        return
    fi

    if (( $edit == 1 )); then
        __edit template "$template"
        return
    fi

    echo "nothing to do"
}

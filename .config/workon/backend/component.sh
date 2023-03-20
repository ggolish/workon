#!/bin/bash

function __include_component {
    while (( $# > 0 )); do
        local component="$1"
        if [[ -z "$component" ]]; then
            echo "must provide component name" >&2
            return
        fi

        local path="$WORKON_COMPONENTS_DIR/$component.sh"
        [[ ! -e "$path" ]] && echo "component $component does not exist" && return
        source "$path"

        if ! __function_exists "__component_launch"; then
            echo "component $component does not define __component_launch"
        else
            __component_launch
            unset __component_launch
        fi
        if ! __function_exists "__component_clean"; then
            echo "component $component does not define __component_clean"
        else
            unset __component_clean
        fi
        shift
    done
}

function __clean_component {
    while (( $# > 0 )); do
        local component="$1"
        if [[ -z "$component" ]]; then
            echo "must provide component name" >&2
            return
        fi

        local path="$WORKON_COMPONENTS_DIR/$component.sh"
        [[ ! -e "$path" ]] && echo "component $component does not exist" && return
        source "$path"

        if ! __function_exists "__component_clean"; then
            echo "component $component does not define __component_clean"
        else
            __component_clean
            unset __component_clean
        fi
        if ! __function_exists "__component_launch"; then
            echo "component $component does not define __component_launch"
        else
            unset __component_launch
        fi
        shift
    done
}

function __component_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local component="$4"

    if (( $new == 1 )); then
        __new component "$component"
        return
    fi

    if (( $remove == 1 )); then
        __remove component "$component"
        return
    fi

    if (( $edit == 1 )); then
        __edit component "$component"
        return
    fi

    echo "nothing to do"
}

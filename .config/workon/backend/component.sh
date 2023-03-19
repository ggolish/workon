#!/bin/bash

function __include_component {
    while (( $# > 0 )); do
        local component="$1"
        if [[ -z "$component" ]]; then
            echo "must provide component name" >&2
            return
        fi

        local path="$(__get_full_component "$component")"
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

        local path="$(__get_full_component "$component")"
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

function __new_component {
    local component="$1"
    if [[ -z "$component" ]]; then
        echo "must provide component name" >&2
        return
    fi
    if [[ -f "$(__get_full_component $component)" ]]; then
        echo "component $component already exists"
        return
    fi
    local base_component="$(__component_select)"
    [[ -z "$base_component" ]] && base_component="base"
    cp "$(__get_full_component $base_component)" "$(__get_full_component $1)" && \
        __edit_component "$component"
}

function __remove_component {
    local component="$1"
    if [[ -z "$component" ]]; then
        component="$(__component_select)"
        [[ -z "$component" ]] && return
    fi

    if [[ "$component" == "base" ]]; then
        echo "can not edit base component"
        return
    fi

    if __prompt "Remove component $component"; then
        rm "$(__get_full_component $component)" || echo "failed to remove component $component"
    fi
}

function __edit_component {
    local component="$1"
    if [[ -z "$component" ]]; then
        component="$(__component_select)"
        [[ -z "$component" ]] && return
    fi

    if [[ "$component" == "base" ]]; then
        echo "can not edit base component"
        return
    fi

    $EDITOR "$(__get_full_component $component)"
}

function __list_components {
    local quiet=$(__component_select)
}

function __component_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local component="$4"

    if (( $new == 1 )); then
        __new_component "$component"
        return
    fi

    if (( $remove == 1 )); then
        __remove_component "$component"
        return
    fi

    if (( $edit == 1 )); then
        __edit_component "$component"
        return
    fi

    __list_components
}

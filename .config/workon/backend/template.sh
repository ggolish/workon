#!/bin/bash

function __new_template {
    local template="$1"
    if [[ -z "$template" ]]; then
        echo "must provide template name" >&2
        return
    fi
    if [[ -f "$(__get_full_template $template)" ]]; then
        echo "template $template already exists"
        return
    fi
    local base_template="$(__template_select)"
    [[ -z "$base_template" ]] && base_template="base"
    cp "$(__get_full_template $base_template)" "$(__get_full_template $1)" && \
        __edit_template "$template"
}

function __remove_template {
    local template="$1"
    if [[ -z "$template" ]]; then
        template="$(__template_select)"
        [[ -z "$template" ]] && return
    fi

    if [[ "$template" == "base" ]]; then
        echo "can not remove base template"
        return
    fi
    if __prompt "Remove template $template"; then
        rm "$(__get_full_template $template)" || echo "failed to remove template $template"
    fi
}

function __edit_template {
    local template="$1"
    if [[ -z "$template" ]]; then
        template="$(__template_select)"
        [[ -z "$template" ]] && return
    fi

    if [[ "$template" == "base" ]]; then
        echo "can not edit base template"
        return
    fi

    $EDITOR "$(__get_full_template $template)"
}

function __list_templates {
    local quiet=$(__template_select)
}

function __template_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local template="$4"

    if (( $new == 1 )); then
        __new_template "$template"
        return
    fi

    if (( $remove == 1 )); then
        __remove_template "$template"
        return
    fi

    if (( $edit == 1 )); then
        __edit_template "$template"
        return
    fi

    __list_templates
}

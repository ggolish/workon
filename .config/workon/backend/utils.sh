#!/bin/bash

# prompt prompts the user for a yes or no, return true or false repectively
function __prompt {
    echo -n "$1? [y/N] "
    read choice
    case "$choice" in
        y|Y)
            return
            ;;
    esac
    false
}

# get_full_profile converts a profile name to its actual path
function __get_full_profile {
    echo "$WORKON_PROFILES_DIR/$1.sh"
}

# get_full_template converts a template name to its actual path
function __get_full_template {
    echo "$WORKON_TEMPLATES_DIR/$1.sh"
}

# profile_exists checks if a profiles exists in the profiles directory
function __profile_exists {
    [[ -f "$(__get_full_profile $1)" ]]
}

# function_exists checks if a function has been defined by name - useful to
# check if a profile or util has defined an expected function
function __function_exists {
    [[ $(type -t $1) == function ]]
}

# ensure_profile_dir ensures the profiles directory exists
function __ensure_profile_dir {
    mkdir -p $WORKON_PROFILES_DIR
}

# template_select prompts the user to select a template via fzf
function __template_select {
    __file_select "$WORKON_TEMPLATES_DIR" "Select a template"
}

# profile_select prompts the user to select a profile via fzf
function __profile_select {
    __file_select "$WORKON_PROFILES_DIR" "Select a profile"
}

# file_select prompts the user to select a bash file in a specified directory
function __file_select {
    local file_dir="$1"
    local prompt="$2"
    find -L "$file_dir" -name "*.sh" -exec basename {} .sh \; | \
        fzf --prompt="$prompt: " --preview="cat $file_dir/{}.sh"
}

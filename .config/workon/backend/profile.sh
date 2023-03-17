#!/bin/bash

# activate_profile brings a new profile into scope by sourcing the appropriate
# bash script.
function __activate_profile {
    local profile="$1"
    if ! __profile_exists "$profile"; then
        echo "profile '$profile' does not exist"
        return
    fi

    unset __profile_launch

    WORKON_CURRENT_PROFILE="$profile"
    source "$(__get_full_profile $profile)" || return

    # Store the profile name to be used as tmux session name if necessary
    WORKON_SESSION_NAME="$profile"

    if ! __function_exists __profile_launch; then
        echo "profile '$profile' does not implement '__profile_launch'"
        return
    fi

    unset __util_activate
    for util in $WORKON_UTILS_DIR/*.sh; do
        source "$util" || continue
        if ! __function_exists __util_activate; then
            continue
        fi
        __util_activate || echo "failed to activate util '$util'"
        unset __util_activate
    done

    if [[ ! -z "$BR" ]]; then
        # store the directory workon was ran from so it can be returned to
        # after cleanup has been called
        WORKON_RETURN_DIR=$(pwd)

        # create BR if it does not yet exist
        mkdir -p $BR
        cd "$BR"
        alias ,="cd $BR"
    fi

    # Launch in tmux if specified, cleanup afterward
    if [[ ! -z "$WORKON_USE_TMUX" ]]; then
        __launch_tmux "$profile" "$BR" "$WORKON_SESSION_NAME"
        __cleanup_profile
        return
    fi

    # Set the window name if running in tmux
    if [[ -n "$TMUX" ]]; then
        tmux rename-window "$profile"
    fi

    # profiles must be launched after utils have been activated to allow the util
    # to modify the launch function if necessary
    __profile_launch || return
}

# cleanup_profile cleans up the current active profile
function __cleanup_profile {
    if [[ ! -z "$WORKON_CURRENT_PROFILE" ]]; then
        if __function_exists __profile_clean; then
            __profile_clean || echo "failed to clean profile '$WORKON_CURRENT_PROFILE'"
            unset __profile_clean
        fi
    fi

    unset __util_clean
    for util in $WORKON_UTILS_DIR/*.sh; do
        source "$util" || continue
        if ! __function_exists __util_clean; then
            continue
        fi
        __util_clean || echo "failed to clean util '$util'"
        unset __util_clean
    done

    # return to directory workon was initially called on
    if [[ ! -z "$WORKON_RETURN_DIR" ]]; then
        cd "$WORKON_RETURN_DIR"
    fi

    # clean known functions from utils and profiles
    unset __util_activate
    unset __profile_launch

    # clean known environment variables
    unset BR
    unset WORKON_CURRENT_PROFILE
    unset WORKON_RETURN_DIR
    unset WORKON_USE_TMUX
    unset WORKON_SESSION_NAME
    unset WORKON_TMUX_ENV

    # clean aliases
    alias , &> /dev/null && unalias ,
}

# new_profile creates a new empty default profile
function __new_profile {
    if __profile_exists "$1"; then
        echo "profile '$1' already exists"
        return
    fi

    local template="$(__template_select)"
    [[ -z "$template" ]] && template="base"
    cp "$(__get_full_template $template)" "$(__get_full_profile $1)"
}

# remove_profile deletes an existing profile
function __remove_profile {
    echo -n "Remove profile '$1'? [y/N] "
    read choice
    case "$choice" in
        y|Y)
            rm -f "$(__get_full_profile $1)" || echo "failed to remove profile '$1'"
            ;;
    esac

}

# edit_profile opens a profile in an editor
function __edit_profile {
    $EDITOR "$(__get_full_profile "$1")"
}

# reload_profile cleans the current profile and reloads it
function __reload_profile {
    [[ -z "$WORKON_CURRENT_PROFILE" ]] && return
    local current_dir="$(pwd)"
    if __function_exists __profile_clean; then
        __profile_clean
    fi
    __activate_profile "$WORKON_CURRENT_PROFILE"
    cd "$current_dir"
}


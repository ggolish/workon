#!/bin/bash

# activate_profile brings a new profile into scope by sourcing the appropriate
# bash script.
function __activate_profile {
    local profile="$1"
    local full_path="$WORKON_PROFILES_DIR/$profile.sh"
    if [[ ! -e "$full_path" ]]; then
        echo "profile '$profile' does not exist"
        return
    fi

    unset __profile_launch

    WORKON_CURRENT_PROFILE="$profile"
    source "$full_path" || return

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

    if [[ -n "$WORKON_USE_ZELLIJ" ]]; then
        WORKON_ZELLIJ="$profile" WORKON_GIT_CURRENT_WORKTREE="$WORKON_GIT_CURRENT_WORKTREE" zellij attach -c "$WORKON_SESSION_NAME"
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

function __profile_main {
    local new="$1"
    local remove="$2"
    local edit="$3"
    local clean="$4"
    local profile="$5"

    __ensure_profile_dir

    if [[ -z "$profile" ]]; then
        if (( $new == 1 )); then
            echo "must provide profile name"
            return
        fi
        if (( $clean == 0 )); then
            # If no arguments are provided to edit flag and a current profile
            # is active, edit the current profile and reload the current
            # profile.
            if (( $edit == 1 )) && [[ -n "$WORKON_CURRENT_PROFILE" ]]; then
                __edit profile "$WORKON_CURRENT_PROFILE"
                __reload_profile
                return
            fi
            profile=$(__file_select "$WORKON_PROFILES_DIR" "choose a profile")
            [[ -z "$profile" ]] && return
        fi
    fi

    if (( $new == 1 )); then
        __new profile "$profile"
        return
    fi

    if (( $clean == 1 )); then
        __cleanup_profile "$WORKON_CURRENT_PROFILE"
        return
    fi

    if (( $edit == 1 )); then
        __edit profile "$profile"
        return
    fi

    if (( $remove == 1 )); then
        __remove profile "$profile"
        return
    fi

    # If a workon profile is already active, clean it up
    if [[ -n "$WORKON_CURRENT_PROFILE" ]]; then
        local worktree="$WORKON_GIT_CURRENT_WORKTREE"
        __cleanup_profile "$WORKON_CURRENT_PROFILE"
        # Preserve worktree if switching between profiles
        WORKON_GIT_CURRENT_WORKTREE="$worktree"
    fi

    __activate_profile "$profile"
}

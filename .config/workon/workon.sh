
[[ -z "$WORKON_DIR" ]] && WORKON_DIR="$HOME/.config/workon"
WORKON_PROFILES_DIR="$WORKON_DIR/profiles"
WORKON_UTILS_DIR="$WORKON_DIR/utils"
WORKON_DEFAULTS_DIR="$WORKON_DIR/defaults"

# activate_profile brings a new profile into scope by sourcing the appropriate
# bash script.
function __activate_profile {
    if ! __profile_exists "$1"; then
        echo "profile '$1' does not exist"
        return
    fi

    unset __profile_launch

    source "$(__get_full_profile $1)" || return
    WORKON_CURRENT_PROFILE="$1"

    if ! __function_exists __profile_launch; then
        echo "profile '$1' does not implement '__profile_launch'"
        return
    fi

    unset __util_activate
    for util in $WORKON_UTILS_DIR/*.sh; do
        source "$util" || continue
        if ! __function_exists __util_activate; then
            echo "util '$util' does not implement '__util_activate', skipping"
            continue
        fi
        __util_activate || echo "failed to activate util '$util'"
        unset __util_activate
    done

    if [[ ! -z "$BR" ]]; then
        # store the directory workon was ran from so it can be returned to
        # after cleanup has been called
        WORKON_RETURN_DIR=$(pwd)
        cd "$BR"
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
}

# new_profile creates a new empty default profile
function __new_profile {
    if __profile_exists "$1"; then
        echo "profile '$1' already exists"
        return
    fi

    __ensure_profile_dir
    cp "$(__get_full_default profile)" "$(__get_full_profile $1)"
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

# usage prints usage information
function __usage {
    echo "Usage: workon --new <profile> | workon --clean | workon [--tmux|--edit] [profile]"
}

# get_full_profile converts a profile name to its actual path
function __get_full_profile {
    echo "$WORKON_PROFILES_DIR/$1.sh"
}

# get_full_profile converts a default name to its actual path
function __get_full_default {
    echo "$WORKON_DEFAULTS_DIR/$1.sh"
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

# profile_select prompts the user to select a profile via fzf
function __profile_select {
    find $WORKON_PROFILES_DIR -name "*.sh" -exec basename {} .sh \; | \
        fzf --prompt="Select a profile: " --preview="cat $WORKON_PROFILES_DIR/{}.sh"
}

# launch_tmux launches a new tmux session with the name of the workon profile.
# then it calls workon for that profile and attaches the session.
# Tmux launch rules:
# 1. Will not launch tmux session from within an attached tmux session
# 2. Will not launch tmux session if there is an active workon profile
# 3. Will not launch tmux session if session with same name exists, will just
#    attach instead
function __launch_tmux {
    if [[ ! -z "$WORKON_CURRENT_PROFILE" ]]; then
        echo "failed to launch tmux: workon profile active"
        return
    fi

    if [[ ! -z "$TMUX" ]]; then
        echo "failed to launch tmux: tmux session already attached"
        return
    fi

    local session="$1"

    if tmux has-session -t "$session"; then
        tmux attach -t "$session"
        return
    fi

    tmux new -d -s "$session"
    tmux send-keys -t "$session.0" "workon $session" ENTER
    tmux attach -t "$session"
}

# workon is the actual function the user uses to interact with workon
function workon {
    if (( $# > 2 )); then
        __usage
        return
    fi

    let new=0
    let remove=0
    let clean=0
    let use_tmux=0
    let edit=0

    case "$1" in
        -h|--help)
            __usage
            return
            ;;
        -n|--new)
            let new=1
            shift
            ;;
        -r|--remove)
            let remove=1
            shift
            ;;
        -c|--clean)
            let clean=1
            shift
            ;;
        -t|--tmux)
            let use_tmux=1
            shift
            ;;
        -e|--edit)
            let edit=1
            shift
            ;;
    esac

    if [[ -z "$1" ]]; then
        if (( $new == 1 )); then
            echo "must provide profile name"
            return
        fi
        if (( $clean == 0 )); then
            profile=$(__profile_select)
            [[ -z "$profile" ]] && return
        fi
    else
        profile="$1"
    fi

    if (( $new == 1 )); then
        __new_profile "$profile"
        return
    fi

    if (( $clean == 1 )); then
        __cleanup_profile "$WORKON_CURRENT_PROFILE"
        return
    fi

    if (( $use_tmux == 1 )); then
        __launch_tmux "$profile"
        return
    fi

    if (( $edit == 1 )); then
        $EDITOR "$(__get_full_profile $profile)"
        return
    fi

    if (( $remove == 1 )); then
        __remove_profile "$profile"
        return
    fi

    if [[ ! -z "$WORKON_CURRENT_PROFILE" ]]; then
        echo "profile '$WORKON_CURRENT_PROFILE' already active"
        return
    fi
    __activate_profile "$profile"
}

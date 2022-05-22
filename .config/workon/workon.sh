
[[ -z "$WORKON_DIR" ]] && WORKON_DIR="$HOME/.config/workon"
WORKON_PROFILES_DIR="$WORKON_DIR/profiles"
WORKON_UTILS_DIR="$WORKON_DIR/utils"
WORKON_DEFAULTS_DIR="$WORKON_DIR/defaults"

# activate_profile brings a new profile into scope by sourcing the approprite
# bash script.
function __activate_profile {
    if ! __profile_exists $1; then
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
    for env in $WORKON_UTILS_DIR/*.sh; do
        source "$env" || continue
        if ! __function_exists __util_activate; then
            echo "env '$env' does not implement '__util_activate', skipping"
            continue
        fi
        __util_activate || echo "failed to activate env '$env'"
        unset __util_activate
    done

    if [[ ! -z "$BR" ]]; then
        WORKON_RETURN_DIR=$(pwd)
        cd "$BR"
    fi

    # profiles must be launched after envs have been activated to allow the env
    # to modify the launch function if necessary
    __profile_launch || return
}

# cleanup_profile cleans up the current active profile. Only things that would
# interfere with other profiles will be cleaned up.
function __cleanup_profile {
    if [[ ! -z "$WORKON_CURRENT_PROFILE" ]]; then
        if __function_exists __profile_clean; then
            __profile_clean || echo "failed to clean profile '$WORKON_CURRENT_PROFILE'"
            unset __profile_clean
        fi
    fi

    unset __util_clean
    for env in $WORKON_UTILS_DIR/*.sh; do
        source "$env" || continue
        if ! __function_exists __util_clean; then
            continue
        fi
        __util_clean || echo "failed to clean env '$env'"
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

    __check_profile_dir
    cp "$(__get_full_default profile)" "$(__get_full_profile $1)"
}

# usage prints usage information
function __usage {
    echo "Usage: workon --new <profile> | workon --clean | workon [--tmux|--edit] [profile]"
}

function __get_full_profile {
    echo "$WORKON_PROFILES_DIR/$1.sh"
}

function __get_full_default {
    echo "$WORKON_DEFAULTS_DIR/$1.sh"
}

function __profile_exists {
    [[ -f "$(__get_full_profile $1)" ]]
}

function __function_exists {
    [[ $(type -t $1) == function ]]
}

function __check_profile_dir {
    mkdir -p $WORKON_PROFILES_DIR
}

function __profile_select {
    find $WORKON_PROFILES_DIR -name "*.sh" -exec basename {} .sh \; | \
        fzf --prompt="Select a profile: " --preview="cat $WORKON_PROFILES_DIR/{}.sh"
}

function __launch_tmux {
    tmux new -d -s "$1"
    tmux send-keys -t "$1.0" "workon $1" ENTER
    tmux attach -t "$1"
}

function __remove_profile {
    echo -n "Remove profile '$1'? [y/N] "
    read choice
    case "$choice" in
        y|Y)
            rm -f "$(__get_full_profile $1)" || echo "failed to remove profile '$1'"
            ;;
    esac

}

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

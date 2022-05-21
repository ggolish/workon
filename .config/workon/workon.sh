
[[ -z "$WORKON_DIR" ]] && WORKON_DIR="$HOME/.config/workon"
WORKON_PROFILES_DIR="$WORKON_DIR/profiles"
WORKON_ENV_DIR="$WORKON_DIR/envs"

# activate_profile brings a new profile into scope by sourcing the approprite
# bash script.
function __activate_profile {
    if ! __profile_exists $1; then
        echo "profile '$1' does not exist"
        return
    fi

    unset __profile_launch

    source "$WORKON_PROFILES_DIR/$1.sh" || return
    WORKON_CURRENT_PROFILE="$1"

    if ! __function_exists __profile_launch; then
        echo "profile '$1' does not implement '__profile_launch'"
        return
    fi

    unset __env_activate
    for env in $WORKON_ENV_DIR/*.sh; do
        source "$env" || continue
        if ! __function_exists __env_activate; then
            echo "env '$env' does not implement '__env_activate', skipping"
            continue
        fi
        __env_activate || echo "failed to activate env '$env'"
        unset __env_activate
    done

    [[ ! -z "$BR" ]] && cd "$BR"

    # profiles must be launched after envs have been activated to allow the env
    # to modify the launch function if necessary
    __profile_launch || return
}

# cleanup_profile cleans up the current active profile. Only things that would
# interfere with other profiles will be cleaned up.
function __cleanup_profile {
    echo "unimplemented"
}

# new_profile creates a new empty default profile
function __new_profile {
    if __profile_exists "$1"; then
        echo "profile '$1' already exists"
        return
    fi

    __check_profile_dir
    cp defaults/profile.sh "$WORKON_PROFILES_DIR/$1.sh"
}

# usage prints usage information
function __usage {
    echo "Usage: workon --new <profile> | workon --clean | workon [--tmux] [profile]"
}

function __profile_exists {
    [[ -f "$WORKON_PROFILES_DIR/$1.sh" ]]
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

function workon {
    if (( $# > 2 )); then
        __usage
        return
    fi

    let new=0
    let clean=0
    let use_tmux=0

    case "$1" in
        -h|--help)
            __usage
            return
            ;;
        -n|--new)
            let new=1
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
    esac

    if [[ -z "$1" ]]; then
        if (( $new == 1 )); then
            echo "must provide profile name"
            return
        fi
        profile=$(__profile_select)
        [[ -z "$profile" ]] && echo "cancelled" && popd && return
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

    __activate_profile "$profile"
}

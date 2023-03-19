
[[ -z "$WORKON_DIR" ]] && WORKON_DIR="$HOME/.config/workon"
source "$WORKON_DIR/backend/utils.sh"
source "$WORKON_DIR/backend/tmux.sh"
source "$WORKON_DIR/backend/profile.sh"
source "$WORKON_DIR/backend/template.sh"
source "$WORKON_DIR/backend/component.sh"

WORKON_PROFILES_DIR="$WORKON_DIR/profiles"
WORKON_UTILS_DIR="$WORKON_DIR/utils"
WORKON_TEMPLATES_DIR="$WORKON_DIR/templates"
WORKON_COMPONENTS_DIR="$WORKON_DIR/components"
#
# usage prints usage information
function __usage {
    echo "Usage: workon --new <profile> | workon --clean | workon [--tmux|--edit] [profile]"
}

# workon is the actual function the user uses to interact with workon
function workon {
    if (( $# > 3 )); then
        __usage
        return
    fi

    let template_mode=0
    let component_mode=0

    let new=0
    let remove=0
    let clean=0
    let edit=0

    if [[ "$1" == "--template" ]]; then
        let template_mode=1
        shift
    elif [[ "$1" == "--component" ]]; then
        let component_mode=1
        shift
    fi

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
            WORKON_USE_TMUX=1
            shift
            ;;
        -e|--edit)
            let edit=1
            shift
            ;;
    esac

    __ensure_profile_dir

    if (( $template_mode == 1 )); then
        __template_main "$new" "$remove" "$edit" "$1"
        return
    fi

    if (( $component_mode == 1 )); then
        __component_main "$new" "$remove" "$edit" "$1"
        return
    fi

    if [[ -z "$1" ]]; then
        if (( $new == 1 )); then
            echo "must provide profile name"
            return
        fi
        if (( $clean == 0 )); then
            # If no arguments are provided to edit flag and a current profile
            # is active, edit the current profile and reload the current
            # profile.
            if (( $edit == 1 )) && [[ -n "$WORKON_CURRENT_PROFILE" ]]; then
                __edit_profile "$WORKON_CURRENT_PROFILE"
                __reload_profile
                return
            fi
            profile=$(__profile_select)
            [[ -z "$profile" ]] && return
        fi
    else
        profile="$1"
    fi

    if (( $new == 1 )); then
        __new_profile "$profile"
        $EDITOR "$(__get_full_profile $profile)"
        return
    fi

    if (( $clean == 1 )); then
        __cleanup_profile "$WORKON_CURRENT_PROFILE"
        return
    fi

    if (( $edit == 1 )); then
        __edit_profile "$profile"
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

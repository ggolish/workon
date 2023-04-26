
[[ -z "$WORKON_DIR" ]] && WORKON_DIR="$HOME/.config/workon"
source "$WORKON_DIR/backend/operations.sh"
source "$WORKON_DIR/backend/helpers.sh"
source "$WORKON_DIR/backend/tmux.sh"
source "$WORKON_DIR/backend/profile.sh"
source "$WORKON_DIR/backend/template.sh"
source "$WORKON_DIR/backend/component.sh"
source "$WORKON_DIR/backend/global.sh"
source "$WORKON_DIR/backend/util.sh"

WORKON_PROFILES_DIR="$WORKON_DIR/profiles"
WORKON_UTILS_DIR="$WORKON_DIR/utils"
WORKON_TEMPLATES_DIR="$WORKON_DIR/templates"
WORKON_COMPONENTS_DIR="$WORKON_DIR/components"
WORKON_GLOBALS_DIR="$WORKON_DIR/globals"

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
    let global_mode=0
    let util_mode=0

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
    elif [[ "$1" == "--global" ]]; then
        let global_mode=1
        shift
    elif [[ "$1" == "--util" ]]; then
        let util_mode=1
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
        -z|--zellij)
            WORKON_USE_ZELLIJ=1
            shift
    esac

    if (( $template_mode == 1 )); then
        __template_main "$new" "$remove" "$edit" "$1"
        return
    fi

    if (( $component_mode == 1 )); then
        __component_main "$new" "$remove" "$edit" "$1"
        return
    fi

    if (( $global_mode == 1 )); then
        __global_main "$new" "$remove" "$edit" "$1"
        return
    fi

    if (( $util_mode == 1 )); then
        __util_main "$new" "$remove" "$edit" "$1"
        return
    fi

    __profile_main "$new" "$remove" "$edit" "$clean" "$1"
}

# Globals are sourced alongside workon and are always available
__load_globals

[[ "$ZELLIJ" == "0" ]] && [[ -n "$WORKON_ZELLIJ" ]] && [[ -z "$WORKON_CURRENT_PROFILE" ]] && workon "$WORKON_ZELLIJ"

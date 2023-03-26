function __new {
    local type="$1"
    local name="$2"
    local dest_dir=""
    local template_dir=""

    if [[ -z "$name" ]]; then
        echo "must provide $type name"
        return
    fi

    case "$type" in
        template)
            dest_dir="$WORKON_TEMPLATES_DIR"
            template_dir="$WORKON_TEMPLATES_DIR"
            ;;
        component)
            dest_dir="$WORKON_COMPONENTS_DIR"
            template_dir="$WORKON_COMPONENTS_DIR"
            ;;
        profile)
            dest_dir="$WORKON_PROFILES_DIR"
            template_dir="$WORKON_TEMPLATES_DIR"
            ;;
        global)
            dest_dir="$WORKON_GLOBALS_DIR"
            template_dir=""
            ;;
        util)
            dest_dir="$WORKON_UTILS_DIR"
            template_dir="$WORKON_UTILS_DIR"
            ;;
        *)
            echo "type $type unknown"
            return
            ;;
    esac

    local full_path="$dest_dir/$name.sh"
    if [[ -e "$full_path" ]]; then
        echo "$type $name already exists"
        return
    fi

    if [[ -z "$template_dir" ]]; then
        touch "$full_path" && __edit "$type" "$name"
        return
    fi

    local base=$(__file_select "$template_dir" "choose $type template")
    [[ -z "$base" ]] && base="base"
    local base_path="$template_dir/$base.sh"
    cp "$base_path" "$full_path" && __edit "$type" "$name"
}

function __edit {
    local type="$1"
    local name="$2"
    local dest_dir=""
    case "$type" in
        template)
            dest_dir="$WORKON_TEMPLATES_DIR"
            ;;
        component)
            dest_dir="$WORKON_COMPONENTS_DIR"
            ;;
        profile)
            dest_dir="$WORKON_PROFILES_DIR"
            ;;
        global)
            dest_dir="$WORKON_GLOBALS_DIR"
            ;;
        util)
            dest_dir="$WORKON_UTILS_DIR"
            ;;
        *)
            echo "type $type unknown"
            return
            ;;
    esac

    if [[ -z "$name" ]]; then
        name="$(__file_select "$dest_dir" "choose $type")"
        [[ -z "$name" ]] && return
    fi

    local full_path="$dest_dir/$name.sh"
    if [[ ! -e "$full_path" ]]; then
        echo "$type $name does not exist"
        return
    fi

    if __is_forbidden "$type" "$name"; then
        echo "$type $name can not be modified"
        return
    fi

    if [[ ! -e "$full_path" ]]; then
        echo "$type $name does not exist"
        return
    fi

    $EDITOR "$full_path"
}

function __remove {
    local type="$1"
    local name="$2"
    local dest_dir=""
    case "$type" in
        template)
            dest_dir="$WORKON_TEMPLATES_DIR"
            ;;
        component)
            dest_dir="$WORKON_COMPONENTS_DIR"
            ;;
        profile)
            dest_dir="$WORKON_PROFILES_DIR"
            ;;
        global)
            dest_dir="$WORKON_GLOBALS_DIR"
            ;;
        util)
            dest_dir="$WORKON_UTILS_DIR"
            ;;
        *)
            echo "type $type unknown"
            return
            ;;
    esac

    if [[ -z "$name" ]]; then
        name="$(__file_select "$dest_dir" "choose $type")"
        [[ -z "$name" ]] && return
    fi

    local full_path="$dest_dir/$name.sh"
    if [[ ! -e "$full_path" ]]; then
        echo "$type $name does not exist"
        return
    fi

    if __is_forbidden "$type" "$name"; then
        echo "$type $name can not be removed"
        return
    fi

    if [[ ! -e "$full_path" ]]; then
        echo "$type $name does not exist"
        return
    fi

    if __prompt "Delete $type $name"; then
        rm "$full_path"
    fi
}

function __is_forbidden {
    local type="$1"
    local name="$2"
    local forbidden_list=()
    case "$type" in
        template)
            forbidden_list=("base")
            ;;
        component)
            forbidden_list=("base")
            ;;
        util)
            forbidden_list=("base")
            ;;
        *)
            forbidden_list=()
            ;;
    esac

    for forbidden in ${forbidden_list[@]}; do
        if [[ "$name" == "$forbidden" ]]; then
            return
        fi
    done

    false
}

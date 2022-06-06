# Variables that MUST be set:
# BR => The profile root will be used as the destination of the git repo.
# WORKON_GIT_REMOTE => A remote git URL for the repo that will be used to fetch
#   the repo if it does not exist at $BR
#
# Variables that CAN be set:
# WORKON_GIT_ROOT => Will take the place of $BR as the destination of the git
#   repo. If it is set, then $BR should be set to a relative path to a
#   subdirectory of the git repo.
# WORKON_GIT_WORKTREES => Enables worktree mode. It will assume that $BR points
#   to a directory containing subdirectories that are actually worktrees of the
#   repo, where $BR/master contains the actual repo itself. Then the user will
#   be prompted to choose a worktree, which will be appended to $BR.
# WORKON_GIT_CURRENT_WORKTREE => Specifies the chosen worktree

function __fetch_repo {
    if [[ ! -z "$WORKON_GIT_WORKTREES" ]]; then
        mkdir -p "$1"
        git clone "$WORKON_GIT_REMOTE" "$1/master"
        return
    fi
    git clone "$WORKON_GIT_REMOTE" "$1"
}

function __worktree_select {
    choice=$(ls -1 "$1" | fzf --prompt "Choose worktree: ")
    # Default to the master branch
    [[ -z "$choice" ]] && choice="master"
    echo "$choice"
}

function __update_br {
    work_tree="$1"
    if [[ ! -z "$WORKON_GIT_ROOT" ]]; then
        prepend="$WORKON_GIT_ROOT"
        if [[ ! -z "$work_tree" ]]; then
            prepend="$prepend/$work_tree"
        fi
        BR="$prepend/$BR"
        return
    fi

    if [[ ! -z "$work_tree" ]]; then
        BR="$BR/$work_tree"
    fi
}

function __create_repo {
    local git_root="$1"
    if [[ -z "$git_root" ]]; then
        return $(false)
    fi

    if [[ ! -z "$WORKON_GIT_WORKTREES" ]]; then
        git_root="$git_root/master"
    fi

    mkdir -p "$git_root"
    git -C "$git_root" init
    if [[ ! -z "$WORKON_GIT_ROOT" ]]; then
        mkdir -p "$git_root/$BR"
    fi
}

function __util_activate {
    if [[ -z "$BR" ]] || [[ -z "$WORKON_GIT_REMOTE" ]]; then
        return
    fi

    git_root="$BR"
    if [[ ! -z "$WORKON_GIT_ROOT" ]]; then
        git_root="$WORKON_GIT_ROOT"
        alias ,,="cd $WORKON_GIT_ROOT"
    else
        alias ,,="cd $BR"
    fi

    if [[ ! -d "$git_root" ]]; then
        if __prompt "Git repo not found, fetch from remote"; then
            if ! __fetch_repo "$git_root"; then
                echo "failed to fetch git repo $WORKON_GIT_REMOTE"
                return $(false)
            fi
        elif __prompt "Create a new repo"; then
            if ! __create_repo "$git_root"; then
                echo "failed to initialize new git repo at '$git_root'"
                return $(false)
            fi
        else
            return $(false)
        fi
    fi

    wt=""
    if [[ ! -z "$WORKON_GIT_WORKTREES" ]]; then
        if [[ -z "$WORKON_GIT_CURRENT_WORKTREE" ]]; then
            wt="$(__worktree_select "$git_root")"
            WORKON_SESSION_NAME="$WORKON_SESSION_NAME-$wt"
            __tmux_env_append "WORKON_GIT_CURRENT_WORKTREE=$wt"
        else
            wt="$WORKON_GIT_CURRENT_WORKTREE"
        fi
    fi

    __update_br "$wt"
}

function __util_clean {
    unset WORKON_GIT_ROOT
    unset WORKON_GIT_REMOTE
    unset WORKON_GIT_WORKTREES
    unset WORKON_GIT_CURRENT_WORKTREE

    unalias ,,
}

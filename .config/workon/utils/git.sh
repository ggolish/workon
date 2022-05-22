# Variables that MUST be set:
# BR => The profile root will be used as the destination of the git repo.
# WORKON_GIT_REMOTE => A remote git URL for the repo that will be used to fetch
#   the repo if it does not exist at $BR
#
# Variables that CAN be set:
# WORKON_GIT_WORKTREES => Enables worktree mode. It will assume that $BR points
#   to a directory containing subdirectories that are actually worktrees of the
#   repo, where $BR/master contains the actual repo itself. Then the user will
#   be prompted to choose a worktree, which will be appended to $BR.

function __fetch_repo {
    if [[ ! -z "$WORKON_GIT_WORKTREES" ]]; then
        mkdir -p "$BR"
        git clone "$WORKON_GIT_REMOTE" "$BR/master"
        return
    fi
    git clone "$WORKON_GIT_REMOTE" "$BR"
}

function __worktree_select {
    choice=$(ls -1 "$BR" | fzf --prompt "Choose worktree: ")

    # Default to the master branch
    [[ -z "$choice" ]] && choice="master"

    if [[ ! -d "$BR/$choice" ]]; then
        echo "worktree '$BR/$choice' does not exist, skipping"
        return
    fi

    BR="$BR/$choice"
}

function __util_activate {
    if [[ -z "$BR" ]] || [[ -z "$WORKON_GIT_REMOTE" ]]; then
        return
    fi

    if [[ ! -d "$BR" ]]; then
        # FUTURE: allow for creating and initializing a new repo at $BR if it
        # is unable to be fetched from the remote link. The new function should:
        #   - prompt the user to see if they want to
        #   - create the directory and initialize git
        #   - set origin to the remote link
        if ! __fetch_repo; then
            echo "failed to fetch git repo $WORKON_GIT_REMOTE"
            return
        fi
    fi

    [[ ! -z "$WORKON_GIT_WORKTREES" ]] && __worktree_select
}

function __util_clean {
    unset WORKON_GIT_REMOTE
    unset WORKON_GIT_WORKTREES
}

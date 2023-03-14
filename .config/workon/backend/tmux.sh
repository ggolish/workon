#!/bin/bash

# launch_tmux launches a new tmux session with the name of the workon profile.
# then it calls workon for that profile and attaches the session.
# Tmux launch rules:
# 1. Will not launch tmux session from within an attached tmux session
# 2. Will not launch tmux session if there is an active workon profile
# 3. Will not launch tmux session if session with same name exists, will just
#    attach instead
function __launch_tmux {
    if [[ ! -z "$TMUX" ]]; then
        echo "failed to launch tmux: tmux session already attached"
        return
    fi

    local profile="$1"
    local working_dir="$2"
    local session="$3"

    if tmux has-session -t "$session" 2> /dev/null; then
        tmux attach -t "$session"
        return
    fi

    echo "$WORKON_TMUX_ENV" | xargs tmux new -d -s "$session" -c "$working_dir"
    tmux send-keys -t "$session.0" "workon $profile" ENTER
    tmux attach -t "$session"
}

# tmux_env_append appends an environment variable to the env that will be
# passed to the new tmux session
function __tmux_env_append {
    local v="$1"
    if [[ -z "$WORKON_TMUX_ENV" ]]; then
        WORKON_TMUX_ENV="-e $v"
    else
        WORKON_TMUX_ENV="$WORKON_TMUX_ENV -e $v"
    fi
}


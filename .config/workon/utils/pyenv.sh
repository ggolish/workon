# Variables that MUST be set:
# WORKON_PYENV_VIRTUALENV => The desired virtualenv name
#
# Variables that CAN be set:
# WORKON_PYENV_VERSION => The desired python version for the virtualenv

function __ensure_pyenv {
    [[ ! -z $(which pyenv 2> /dev/null) ]] && [[ ! -z $PYENV_VIRTUALENV_INIT ]]
}

function __ensure_pyenv_virtualenv {
    if [[ ! -z $(pyenv virtualenvs | awk '{print $1}' | grep $WORKON_PYENV_VIRTUALENV) ]]; then
        return
    fi

    if [[ -z "$WORKON_PYENV_VERSION" ]]; then
        pyenv virtualenv $WORKON_PYENV_VIRTUALENV
    else
        if [[ -z $(pyenv versions | awk '{print $1}' | grep $WORKON_PYENV_VERSION) ]]; then
            pyenv install "$WORKON_PYENV_VERSION"
        fi
        pyenv virtualenv $WORKON_PYENV_VERSION $WORKON_PYENV_VIRTUALENV
    fi
}

function __util_activate {
    if [[ -z "$WORKON_PYENV_VIRTUALENV" ]]; then
        # Tmux (somehow) leaks pyenv sessions sometimes. If the profile does
        # not set a venv then we need to make sure one is not active.
        if [[ -n "$PYENV_VIRTUAL_ENV" ]]; then
            pyenv deactivate
        fi
        return
    fi
    if ! __ensure_pyenv; then
        echo "pyenv is not initialized"
        return
    fi
    __ensure_pyenv_virtualenv
    pyenv activate $WORKON_PYENV_VIRTUALENV && WORKON_PYENV_ACTIVE=1
}

function __util_clean {
    if [[ -z "$WORKON_PYENV_VIRTUALENV" ]]; then
        return
    fi

    if [[ ! -z $WORKON_PYENV_ACTIVE ]]; then
        pyenv deactivate
    fi

    unset WORKON_PYENV_ACTIVE
    unset WORKON_PYENV_VIRTUALENV
    unset WORKON_PYENV_VERSION
}

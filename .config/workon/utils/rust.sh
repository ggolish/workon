# Variables that MUST be set:
# WORKON_RUST_VERSION => The channel/version of Rust to be used for the profile.
#
# Variables that CAN be set:
# WORKON_RUST_UPDATE => Keep the rust channel up to date, useful for when using
#   a channel like stable or nightly.

function __util_activate {
    [[ -z "$WORKON_RUST_VERSION" ]] && return
    if [[ -z $(rustup show | grep "^$WORKON_RUST_VERSION") ]]; then
        echo "Installing rust $WORKON_RUST_VERSION toolchain..."
        rustup toolchain install "$WORKON_RUST_VERSION" || return

    fi

    export RUSTUP_TOOLCHAIN="$WORKON_RUST_VERSION"
    if [[ -n "$WORKON_RUST_UPDATE" ]]; then
        echo "Updating rust $WORKON_RUST_VERSION..."
        rustup update "$WORKON_RUST_VERSION" &> /dev/null
    fi

    if [[ -z $(rustup component list --toolchain "$WORKON_RUST_VERSION" | grep '^rust-analyzer') ]]; then
        echo "Installing rust-analyzer..."
        if ! rustup component add --toolchain "$WORKON_RUST_VERSION" rust-analyzer; then
            echo "Unable to install rust-analyzer for rust $WORKON_RUST_VERSION!"
        fi
    fi
}

function __util_clean {
    unset RUSTUP_TOOLCHAIN
    unset WORKON_RUST_VERSION
    unset WORKON_RUST_UPDATE
}

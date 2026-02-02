#!/bin/bash
# Entrypoint for LocalTerra container
#
# Handles:
# - First-time initialization
# - Starting the node
# - Custom commands

set -e

TERRA_HOME="${TERRA_HOME:-$HOME/.terra}"

# Check if chain is initialized
if [ ! -f "$TERRA_HOME/config/genesis.json" ]; then
    echo "First run detected - initializing chain..."
    /usr/local/bin/init-chain.sh
fi

# Handle command
case "$1" in
    start)
        echo "Starting LocalTerra..."
        exec terrad start --home "$TERRA_HOME"
        ;;
    init)
        echo "Re-initializing chain..."
        rm -rf "$TERRA_HOME"/*
        /usr/local/bin/init-chain.sh
        ;;
    keys)
        shift
        exec terrad keys --keyring-backend test --home "$TERRA_HOME" "$@"
        ;;
    query)
        shift
        exec terrad query --home "$TERRA_HOME" "$@"
        ;;
    tx)
        shift
        exec terrad tx --keyring-backend test --home "$TERRA_HOME" "$@"
        ;;
    *)
        # Pass through any other commands
        exec terrad --home "$TERRA_HOME" "$@"
        ;;
esac

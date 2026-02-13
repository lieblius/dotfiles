#!/bin/bash

MANAGER="$HOME/.config/codeartifact-auth-manager/manager.py"

if [[ ! -f "$MANAGER" ]]; then
    exit 1
fi

# Set PATH to include common locations
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"

# Run refresh in background so click handler returns immediately
(
    "$MANAGER" refresh
    # Force update the specific item directly instead of using trigger
    sketchybar --update codeartifact
) > /dev/null 2>&1 &

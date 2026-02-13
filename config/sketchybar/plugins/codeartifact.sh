#!/bin/bash
set -eu

# Ensure PATH includes locations for uv and aws
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"

MANAGER="$HOME/.config/codeartifact-auth-manager/manager.py"

if [[ ! -f "$MANAGER" ]]; then
    sketchybar --set "$NAME" label="⚠️ No manager"
    exit 1
fi

# Get status
CLICK_SCRIPT=$(dirname "$0")/codeartifact_click.sh

# Check if authenticated by exit code
if "$MANAGER" status &>/dev/null; then
    # Authenticated - filled checkbox
    sketchybar --set "$NAME" \
        icon="󰄲" \
        icon.color=0xffffffff \
        label="" \
        click_script="$CLICK_SCRIPT"
else
    # Not authenticated - empty checkbox
    sketchybar --set "$NAME" \
        icon="󰄱" \
        icon.color=0xffffffff \
        label="" \
        click_script="$CLICK_SCRIPT"
fi

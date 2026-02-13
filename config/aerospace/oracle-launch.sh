#!/bin/bash
# =============================================================================
# Oracle Panel Launcher
# =============================================================================
# Launches a single floating wezterm panel that follows you across workspaces
# via the oracle-follow.sh hook.
#
# Usage: ~/.config/aerospace/oracle-launch.sh
# Kill:  ~/.config/aerospace/oracle-launch.sh kill

ORACLE_ID_FILE="/tmp/aerospace-oracle-id"
ORACLE_PID_FILE="/tmp/aerospace-oracle-pid"
ORACLE_X=10
ORACLE_Y=52

# -----------------------------------------------------------------------------
# Kill mode
# -----------------------------------------------------------------------------
if [ "$1" = "kill" ]; then
    if [ -f "$ORACLE_PID_FILE" ]; then
        kill "$(cat "$ORACLE_PID_FILE")" 2>/dev/null
    fi
    pkill -f "wezterm-gui start --always-new-process" 2>/dev/null
    rm -f "$ORACLE_ID_FILE" "$ORACLE_PID_FILE" /tmp/oracle-zoom-state
    echo "Oracle killed"
    exit 0
fi

# -----------------------------------------------------------------------------
# Check if already running
# -----------------------------------------------------------------------------
if [ -f "$ORACLE_PID_FILE" ] && kill -0 "$(cat "$ORACLE_PID_FILE" 2>/dev/null)" 2>/dev/null; then
    echo "Oracle already running"
    exit 0
fi

# Stale state from a dead oracle -- clean up
rm -f "$ORACLE_ID_FILE" "$ORACLE_PID_FILE" /tmp/oracle-visible

# -----------------------------------------------------------------------------
# Launch oracle wezterm
# -----------------------------------------------------------------------------
WEZTERM_ORACLE=1 wezterm start \
    --always-new-process \
    --position "active:${ORACLE_X},${ORACLE_Y}" &

# Poll for PID and window ID (fast loop, no big sleeps)
# The oracle shows as "wezterm-gui" in aerospace, the main terminal as "WezTerm"
for i in $(seq 1 30); do
    sleep 0.2
    ORACLE_PID=$(pgrep -f "wezterm-gui start --always-new-process" | sort -n | tail -1)
    [ -n "$ORACLE_PID" ] || continue
    # Try PID-based detection first, then fall back to app-name match
    ORACLE_ID=$(aerospace list-windows --monitor focused --pid "$ORACLE_PID" --format '%{window-id}' 2>/dev/null | head -1)
    if [ -z "$ORACLE_ID" ]; then
        ORACLE_ID=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' 2>/dev/null \
            | grep '|wezterm-gui$' | head -1 | cut -d'|' -f1)
    fi
    [ -n "$ORACLE_ID" ] && break
done
echo "$ORACLE_PID" > "$ORACLE_PID_FILE"

if [ -n "$ORACLE_ID" ]; then
    aerospace layout floating --window-id "$ORACLE_ID" 2>/dev/null
    echo "$ORACLE_ID" > "$ORACLE_ID_FILE"
    echo "Oracle launched (window-id: $ORACLE_ID, pid: $ORACLE_PID)"
else
    echo "Error: Could not detect oracle window"
    rm -f "$ORACLE_ID_FILE"
    exit 1
fi

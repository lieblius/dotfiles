#!/bin/bash
# =============================================================================
# Oracle Panel Toggle
# =============================================================================
# First call spawns the oracle window (one-time cost). Subsequent calls:
#   - If oracle is visible and focused  → hide it
#   - If oracle is visible but not focused → focus it
#   - If oracle is hidden → show it
#   - If oracle doesn't exist → launch it
#
# Usage: ~/.config/aerospace/oracle-toggle.sh

LAUNCH="$HOME/.config/aerospace/oracle-launch.sh"
ORACLE_PID_FILE="/tmp/aerospace-oracle-pid"
ORACLE_ID_FILE="/tmp/aerospace-oracle-id"
ORACLE_VISIBLE="/tmp/oracle-visible"
STATE_FILE="/tmp/oracle-zoom-state"
GUTTER_OFF=10

# -----------------------------------------------------------------------------
# Zoom level definitions
# -----------------------------------------------------------------------------
resolve_zoom() {
    local state=$(cat "$STATE_FILE" 2>/dev/null || echo "sidebar")
    case "$state" in
        half) G=874;  OX=10; OY=52; OW=854;  OH=1055 ;;
        full) G=1718; OX=5;  OY=52; OW=1718; OH=1055 ;;
        *)    G=400;  OX=10; OY=52; OW=380;  OH=1055 ;;
    esac
}

oracle_alive() {
    [ -f "$ORACLE_PID_FILE" ] && kill -0 "$(cat "$ORACLE_PID_FILE" 2>/dev/null)" 2>/dev/null
}

oracle_move() {
    local pid=$(cat "$ORACLE_PID_FILE" 2>/dev/null)
    [ -n "$pid" ] || return
    osascript -e "
        tell application \"System Events\"
            tell (first process whose unix id is ${pid})
                set position of window 1 to {$1, $2}
                set size of window 1 to {$3, $4}
            end tell
        end tell
    " 2>/dev/null
}

oracle_focused() {
    local oracle_id=$(cat "$ORACLE_ID_FILE" 2>/dev/null)
    [ -n "$oracle_id" ] || return 1
    local focused_id=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
    [ "$oracle_id" = "$focused_id" ]
}

# -----------------------------------------------------------------------------
# Toggle logic
# -----------------------------------------------------------------------------
if [ -f "$ORACLE_VISIBLE" ] && ! oracle_alive; then
    # Oracle died while marked visible -- clean up stale state and relaunch
    rm -f "$ORACLE_VISIBLE" "$ORACLE_PID_FILE" "$ORACLE_ID_FILE"
fi

if [ -f "$ORACLE_VISIBLE" ]; then
    if oracle_focused; then
        # -------------------------------------------------------------
        # Hide: oracle is focused, user wants to dismiss it
        # -------------------------------------------------------------
        oracle_move 1720 1110 1 1
        aerospace set-gap outer.left "$GUTTER_OFF"
        rm -f "$ORACLE_VISIBLE"
    else
        # -------------------------------------------------------------
        # Focus: oracle is visible but not focused
        # -------------------------------------------------------------
        ORACLE_ID=$(cat "$ORACLE_ID_FILE" 2>/dev/null)
        [ -n "$ORACLE_ID" ] && aerospace focus --window-id "$ORACLE_ID" 2>/dev/null
    fi

elif oracle_alive; then
    # -----------------------------------------------------------------
    # Show: oracle exists but is hidden -- restore last zoom state
    # -----------------------------------------------------------------
    resolve_zoom
    aerospace set-gap outer.left "$G"
    oracle_move "$OX" "$OY" "$OW" "$OH"
    touch "$ORACLE_VISIBLE"

else
    # -----------------------------------------------------------------
    # First launch: spawn the window (one-time cost)
    # -----------------------------------------------------------------
    resolve_zoom
    aerospace set-gap outer.left "$G"
    [ -f "$STATE_FILE" ] || echo "sidebar" > "$STATE_FILE"

    "$LAUNCH" 2>/dev/null

    oracle_move "$OX" "$OY" "$OW" "$OH"
    touch "$ORACLE_VISIBLE"
fi

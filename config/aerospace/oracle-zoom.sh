#!/bin/bash
# =============================================================================
# Oracle Zoom Cycle
# =============================================================================
# Cycles the oracle panel through three sizes:
#   sidebar -> half -> full -> sidebar
# Uses set-gap for instant gutter change, osascript for single window resize.
#
# Usage: ~/.config/aerospace/oracle-zoom.sh

STATE_FILE="/tmp/oracle-zoom-state"
ORACLE_PID_FILE="/tmp/aerospace-oracle-pid"

# -----------------------------------------------------------------------------
# Zoom levels: gutter, oracle x, y, w, h
# -----------------------------------------------------------------------------
SIDEBAR_GUTTER=400
SIDEBAR_X=10  SIDEBAR_Y=52  SIDEBAR_W=380  SIDEBAR_H=1055

HALF_GUTTER=874
HALF_X=10     HALF_Y=52     HALF_W=854     HALF_H=1055

FULL_GUTTER=1718
FULL_X=5      FULL_Y=52     FULL_W=1718    FULL_H=1055

# -----------------------------------------------------------------------------
# Check oracle is running
# -----------------------------------------------------------------------------
[ -f "$ORACLE_PID_FILE" ] || exit 0
ORACLE_PID=$(cat "$ORACLE_PID_FILE")
[ -n "$ORACLE_PID" ] || exit 0

# -----------------------------------------------------------------------------
# Determine next state
# -----------------------------------------------------------------------------
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "sidebar")

case "$CURRENT" in
    sidebar) NEXT="half"    ; G=$HALF_GUTTER    ; OX=$HALF_X    ; OY=$HALF_Y    ; OW=$HALF_W    ; OH=$HALF_H    ;;
    half)    NEXT="full"    ; G=$FULL_GUTTER    ; OX=$FULL_X    ; OY=$FULL_Y    ; OW=$FULL_W    ; OH=$FULL_H    ;;
    full)    NEXT="sidebar" ; G=$SIDEBAR_GUTTER ; OX=$SIDEBAR_X ; OY=$SIDEBAR_Y ; OW=$SIDEBAR_W ; OH=$SIDEBAR_H ;;
    *)       NEXT="sidebar" ; G=$SIDEBAR_GUTTER ; OX=$SIDEBAR_X ; OY=$SIDEBAR_Y ; OW=$SIDEBAR_W ; OH=$SIDEBAR_H ;;
esac

echo "$NEXT" > "$STATE_FILE"

# -----------------------------------------------------------------------------
# Update gutter and resize oracle (both fast -- no reload needed)
# -----------------------------------------------------------------------------
aerospace set-gap outer.left "$G"

osascript -e "
    tell application \"System Events\"
        tell (first process whose unix id is ${ORACLE_PID})
            set position of window 1 to {${OX}, ${OY}}
            set size of window 1 to {${OW}, ${OH}}
        end tell
    end tell
" 2>/dev/null

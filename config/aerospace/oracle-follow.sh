#!/bin/bash
# =============================================================================
# Oracle Follow
# =============================================================================
# Moves the oracle window to the focused workspace. Called by
# exec-on-workspace-change. Only acts when the oracle is visible.

[ -f /tmp/oracle-visible ] || exit 0

ORACLE_ID=$(cat /tmp/aerospace-oracle-id 2>/dev/null)
[ -n "$ORACLE_ID" ] || exit 0

aerospace move-node-to-workspace --window-id "$ORACLE_ID" "$AEROSPACE_FOCUSED_WORKSPACE" 2>/dev/null

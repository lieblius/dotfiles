#!/bin/bash
set -eu

config_file="$HOME/.config/pg_xbar.conf"

if [[ ! -f "$config_file" ]]; then
    sketchybar --set "$NAME" label="⚠️ No config"
    exit 1
fi

set -a
source "$config_file"
set +a

PD_BINARY="/Users/liebl/Documents/tools/toolbox-rs/pagerduty-xbar/target/release/pagerduty-xbar"

if [[ ! -f "$PD_BINARY" ]]; then
    sketchybar --set "$NAME" label="⚠️ No binary"
    exit 1
fi

PD_STATUS=$("$PD_BINARY" | head -n 1)
CLICK_SCRIPT=$(dirname "$0")/pagerduty_click.sh
sketchybar --set "$NAME" label="$PD_STATUS" \
                         click_script="$CLICK_SCRIPT" \
                         popup.background.border_width=2 \
                         popup.background.corner_radius=6 \
                         popup.background.border_color=0xff7aa2f7 \
                         popup.background.color=0xFF1A1B25 \
                         popup.background.drawing=on

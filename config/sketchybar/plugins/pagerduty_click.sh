#!/bin/bash
set -e

config_file="$HOME/.config/pg_xbar.conf"

if [[ ! -f "$config_file" ]]; then
    exit 1
fi

set -a
source "$config_file"
set +a

PD_BINARY="/Users/liebl/Documents/tools/toolbox-rs/pagerduty-xbar/target/release/pagerduty-xbar"

if [[ ! -f "$PD_BINARY" ]]; then
    exit 1
fi

# Get full PagerDuty schedule output
PD_FULL=$("$PD_BINARY")

# Extract and process the schedule information
SCHEDULE_LINES=$(echo "$PD_FULL" | sed -n '/^Upcoming:/,$p' | sed '1d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^[^a-zA-Z0-9]*//g')

if [ -z "$SCHEDULE_LINES" ]; then
    SCHEDULE_LINES="No upcoming shifts"
fi

# Toggle the popup on/off
sketchybar --set pagerduty popup.drawing=toggle \
                         popup.align=center

# Remove any existing entries first
sketchybar --remove '/pagerduty.schedule.*/' 2>/dev/null || true

# Default styling for popup items
ITEM_DEFAULTS="background.padding_left=7
               background.padding_right=15
               label.padding_left=5
               label.padding_right=5
               label.color=0xffffffff
               label.align=center
               drawing=on"

# Add schedule items to the popup with styling
COUNTER=0
while IFS= read -r line; do
    if [ -n "$line" ]; then
        COUNTER=$((COUNTER + 1))
        sketchybar --add item pagerduty.schedule.$COUNTER popup.pagerduty \
                   --set pagerduty.schedule.$COUNTER label="$line" \
                                                   $ITEM_DEFAULTS
    fi
done <<< "$SCHEDULE_LINES"

# If no schedules were added, add a "No shifts" message
if [ "$COUNTER" -eq 0 ]; then
    sketchybar --add item pagerduty.schedule.none popup.pagerduty \
               --set pagerduty.schedule.none label="No upcoming shifts" \
                                            $ITEM_DEFAULTS
fi

#!/usr/bin/env bash

sketchybar --set "$NAME" background.drawing="$([ "$1" = "$FOCUSED_WORKSPACE" ] && echo "on" || echo "off")"


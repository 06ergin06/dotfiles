#!/bin/bash
# Toggle night light filter
# Usage: toggle-nightlight.sh [temperature]
TEMP=${1:-4000}

if [ -z "$1" ]; then
    # No argument = turn off
    ~/.config/hypr/scripts/apply_nightlight.sh off
else
    # Turn on with temperature
    ~/.config/hypr/scripts/apply_nightlight.sh "$TEMP"
fi

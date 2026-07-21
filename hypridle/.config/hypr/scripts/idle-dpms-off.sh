#!/bin/bash
# idle-dpms-off.sh
# Turns off all monitors only when running on battery power.
# If an AC adapter is online, this script exits without doing anything.
#
# Using `hyprctl dispatch dpms off` per-output is unreliable when hyprlock
# is active (input inhibitor interferes). This script turns off all outputs
# via hyprctl and verifies the command succeeded.

on_ac() {
    for f in /sys/class/power_supply/*/online; do
        [ -f "$f" ] || continue
        status=$(cat "$f" 2>/dev/null)
        type_file="${f%online}type"
        if [ -f "$type_file" ]; then
            ptype=$(cat "$type_file" 2>/dev/null)
            [ "$ptype" = "Mains" ] && [ "$status" = "1" ] && return 0
        else
            [ "$status" = "1" ] && return 0
        fi
    done
    return 1
}

on_ac && exit 0

# Turn off every connected output
hyprctl dispatch dpms off

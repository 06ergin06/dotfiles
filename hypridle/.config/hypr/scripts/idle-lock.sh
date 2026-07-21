#!/bin/bash
# idle-lock.sh
# Locks the screen only when running on battery power.
# If an AC adapter is online, this script exits without doing anything.

on_ac() {
    for f in /sys/class/power_supply/*/online; do
        [ -f "$f" ] || continue
        status=$(cat "$f" 2>/dev/null)
        # type=Mains (AC adapter) + online=1  →  we are on AC
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

pidof hyprlock > /dev/null || loginctl lock-session

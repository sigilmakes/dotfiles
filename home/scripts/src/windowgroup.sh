#!/usr/bin/env bash

# Toggle focused window in/out of a group.
# If the window is ungrouped, tries to merge it into an adjacent group.
# If already grouped, moves it out.

status=$(hyprctl activewindow | grep grouped: | xargs)

if [ "$status" == "grouped: 0" ]; then
    hyprctl dispatch moveintogroup l
    hyprctl dispatch moveintogroup r
    hyprctl dispatch moveintogroup u
    hyprctl dispatch moveintogroup d
else
    hyprctl dispatch moveoutofgroup r
fi

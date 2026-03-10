#!/usr/bin/env bash

# DualSense controller configuration via fuzzel menu.
# Toggle touchpad-as-mouse, set trigger modes (default / gamecube).

TRIGGER_DEVICE="sony-interactive-entertainment-dualsense-wireless-controller-touchpad"

trigger_select() {
    printf "Both\nLeft\nRight\n"
}

option_display() {
    printf "Toggle Touchpad Mouse\nDefault Triggers\nGamecube Triggers\n"
}

set_trigger_mode() {
    local mode_args=("$@")
    local trigger
    trigger=$(trigger_select | fuzzel --dmenu --prompt "Trigger: ")

    case "$trigger" in
        "Left")   dualsensectl trigger left "${mode_args[@]}" ;;
        "Right")  dualsensectl trigger right "${mode_args[@]}" ;;
        "Both")
            dualsensectl trigger left "${mode_args[@]}"
            dualsensectl trigger right "${mode_args[@]}"
            ;;
    esac
}

toggle_touchpad() {
    local state_file="/tmp/dualsense_touchpad_enabled"
    local state

    if [[ -f "$state_file" ]]; then
        state=$(<"$state_file")
    else
        state=true
    fi

    if [[ "$state" == "true" ]]; then
        hyprctl keyword "device[$TRIGGER_DEVICE]:enabled" false
        echo false > "$state_file"
    else
        hyprctl keyword "device[$TRIGGER_DEVICE]:enabled" true
        echo true > "$state_file"
    fi
}

main() {
    local opt
    opt=$(option_display | fuzzel --dmenu --prompt "DualSense: ")

    case "$opt" in
        "Toggle Touchpad Mouse") toggle_touchpad ;;
        "Default Triggers")      set_trigger_mode off ;;
        "Gamecube Triggers")     set_trigger_mode weapon 3 6 6 ;;
    esac
}

main

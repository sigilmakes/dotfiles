# Hyprland input settings
#
# Keyboard layout, mouse sensitivity, touchpad behavior.
# GB (UK) and Russian layouts, toggle with keyboardswitch or caelestia bar.

{ config, pkgs, lib, ... }:

{
    wayland.windowManager.hyprland.settings = {

        input = {
            kb_layout = "gb,ru";
            follow_mouse = 1;
            repeat_delay = 250;
            repeat_rate = 35;
            focus_on_close = 1;

            touchpad = {
                natural_scroll = true;
            };

            sensitivity = 0;
            force_no_accel = true;
        };

        cursor = {
            sync_gsettings_theme = true;
            hotspot_padding = 1;
        };

        binds = {
            scroll_event_delay = 0;
        };

        device = {
            name = "epic mouse V1";
            sensitivity = "-0.5";
        };
    };
}

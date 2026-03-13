# Hyprland window rules — adapted for Caelestia shell.
#
# Caelestia handles its own layer rules for the shell surfaces.
# These rules cover application-level window behavior: opacity,
# floating, special workspace assignments, and game tearing.

{ config, pkgs, lib, ... }:

{
    wayland.windowManager.hyprland.settings = {

        # --- Layout ---
        dwindle = {
            pseudotile = true;
            preserve_split = true;
            smart_split = false;
            smart_resizing = true;
        };

        master = {
            new_status = "master";
        };

        # --- General ---
        general = {
            layout = "dwindle";
            allow_tearing = false;
            gaps_in = 5;
            gaps_out = 10;
            border_size = 1;
            resize_on_border = true;
            extend_border_grab_area = 15;
        };

        # --- Decoration ---
        decoration = {
            rounding = 15;

            blur = {
                enabled = true;
                xray = false;
                special = false;
                ignore_opacity = true;
                new_optimizations = true;
                popups = true;
                input_methods = true;
                size = 8;
                passes = 2;
            };

            shadow = {
                enabled = true;
                range = 20;
                render_power = 3;
            };
        };

        # --- Workspace rules ---
        workspace = [
            "w[tv1]s[false], gapsout:20"
            "f[1]s[false], gapsout:20"
        ];

        # --- Window rules ---
        windowrule = [
            # Global opacity for non-fullscreen windows
            "opacity 1 0.8 override, match:fullscreen false"

            # Apps that should be opaque (native transparency or visual tools)
            "opaque true, match:class vesktop|org\\.quickshell|imv|swappy"

            # Center floating windows (not XWayland — breaks popups)
            "center true, match:float true, match:xwayland false"

            # Ripdrag
            "move (cursor_x+((monitor_w*0))) (cursor_y+((monitor_h*0))), match:title ^(ripdrag)$"

            # --- Float rules ---
            "float true, match:class yad"
            "float true, match:class zenity"
            "float true, match:class wev"
            "float true, match:class org\\.gnome\\.FileRoller"
            "float true, match:class file-roller"
            "float true, match:class blueman-manager"
            "float true, match:class feh"
            "float true, match:class imv"
            "float true, match:class system-config-printer"
            "float true, match:class org\\.quickshell"

            # Float + resize + center
            "float true, match:class org\\.pulseaudio\\.pavucontrol"
            "size 60% 70%, match:class org\\.pulseaudio\\.pavucontrol"
            "center 1, match:class org\\.pulseaudio\\.pavucontrol"

            # Dolphin dialogs
            "float true, match:class ^(org\\.kde\\.dolphin)$, match:title ^(Progress Dialog — Dolphin)$"
            "float true, match:class ^(org\\.kde\\.dolphin)$, match:title ^(Copying — Dolphin)$"

            # Firefox dialogs
            "float true, match:title ^(About Mozilla Firefox)$"
            "float true, match:class ^(firefox)$, match:title ^(Picture-in-Picture)$"
            "float true, match:class ^(firefox)$, match:title ^(Library)$"

            # Terminal system monitors
            "float true, match:class ^(kitty)$, match:title ^(top)$"
            "float true, match:class ^(kitty)$, match:title ^(btop)$"
            "float true, match:class ^(kitty)$, match:title ^(htop)$"

            # Misc float
            "float true, match:title ^(KCalc)$"
            "float true, match:class ^(vlc)$"

            # --- Special workspace assignments ---
            "workspace special:sysmon, match:class btop"
            "workspace special:music, match:class Spotify|feishin|Cider|com\\.github\\.th_ch\\.youtube_music"
            "workspace special:music, match:initial_title ^Spotify( Free)?$"
            "workspace special:communication, match:class vesktop|discord|signal"


            # --- Picture-in-Picture ---
            "move 100%-w-2% 100%-w-3%, match:title Picture(-| )in(-| )[Pp]icture"
            "keep_aspect_ratio true, match:title Picture(-| )in(-| )[Pp]icture"
            "float true, match:title Picture(-| )in(-| )[Pp]icture"
            "pin true, match:title Picture(-| )in(-| )[Pp]icture"

            # --- Creative software (opaque) ---
            "opaque true, match:class krita|gimp|inkscape|darktable|kdenlive|blender|godot"

            # --- Steam ---
            "rounding 10, match:class steam"
            "float true, match:title Friends List, match:class steam"

            # --- Games (tearing + idle inhibit) ---
            "opaque true, match:class (steam_app_(default|[0-9]+))|gamescope"
            "immediate true, match:class (steam_app_(default|[0-9]+))|gamescope"
            "idle_inhibit always, match:class (steam_app_(default|[0-9]+))|gamescope"

            # --- File dialogs ---
            "float true, match:title (Select|Open)( a)? (File|Folder)(s)?"
            "float true, match:title File (Operation|Upload)( Progress)?"
            "float true, match:title .* Properties"
            "float true, match:title Save As"
        ];

        # --- Layer rules ---
        layerrule = [
            # Caelestia shell layer rules
            "no_anim true, match:namespace caelestia-(border-exclusion|area-picker)"
            "animation fade, match:namespace caelestia-(drawers|background)"
            "blur true, match:namespace caelestia-drawers"
            "ignore_alpha 0.57, match:namespace caelestia-drawers"

            # Fuzzel (clipboard/emoji picker)
            "animation popin 80%, match:namespace launcher"
            "blur true, match:namespace launcher"

            # Other overlays
            "animation fade, match:namespace hyprpicker"
            "animation fade, match:namespace selection"
        ];
    };
}

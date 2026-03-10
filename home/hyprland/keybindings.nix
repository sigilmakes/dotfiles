# Hyprland keybindings — original layout preserved, adapted for Caelestia.
#
# Caelestia needs a "global" submap for its D-Bus shortcuts (launcher, lock,
# session, media, brightness, screenshots). Regular Hyprland binds work
# normally inside that submap — only the shell-interaction binds changed.
#
# WHAT CHANGED vs the old config:
#   - Super tap AND Super+A open caelestia launcher (was Super+A → rofi)
#   - Super+L → caelestia lock (was swaylock — same key)
#   - Super+Shift+L → caelestia session menu (was logoutlaunch.sh — same key)
#   - Screenshots route through caelestia (same keys: P, Shift+P, Alt+P, Print)
#   - Media/brightness hardware keys route through caelestia (for OSD)
#   - Volume uses wpctl directly (caelestia shows OSD)
#   - Clipboard uses caelestia/fuzzel (same keys: Super+V, Super+Shift+V)
#   - Super+/ toggles caelestia sidebar (was swaync)
#
# WHAT'S THE SAME:
#   - All window actions (close, float, fullscreen, pin, focus, split, groups)
#   - All workspace binds (Super+1-0, Shift+1-0, Alt+1-0, Ctrl+arrows, etc.)
#   - All app launchers (Return, E, F, D, C)
#   - Super+X → dualsense.sh (was quicklaunch2)
#   - Super+R → caelestia record (was wallbash toggle)
#   - Super+Shift+T → windowgroup.sh (restored)
#   - Resize (Super+Shift+Arrows), move (Super+Shift+Ctrl+Arrows)
#   - Mouse bindings, quake-style terminals
#   - Group navigation (Super+[, Super+])

{ config, pkgs, lib, ... }:

{
    wayland.windowManager.hyprland.settings = {

        "$mainMod" = "Super";

        # Floating window move detection — checks if focused window is floating,
        # moves by pixel offset if so, otherwise uses movewindow dispatcher.
        "$moveactivewindow" = ''grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'';
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        source = ~/.config/hypr/machines/${config.home.hostName}.conf

        # =================================================================
        #   GLOBAL SUBMAP — required for Caelestia shell shortcuts
        # =================================================================
        exec = hyprctl dispatch submap global
        submap = global

        # --- Caelestia launcher (Super tap) ---
        bindi = Super, Super_L, global, caelestia:launcher
        bindin = Super, catchall, global, caelestia:launcherInterrupt
        bindin = Super, mouse:272, global, caelestia:launcherInterrupt
        bindin = Super, mouse:273, global, caelestia:launcherInterrupt
        bindin = Super, mouse:274, global, caelestia:launcherInterrupt
        bindin = Super, mouse:275, global, caelestia:launcherInterrupt
        bindin = Super, mouse:276, global, caelestia:launcherInterrupt
        bindin = Super, mouse:277, global, caelestia:launcherInterrupt
        bindin = Super, mouse_up, global, caelestia:launcherInterrupt
        bindin = Super, mouse_down, global, caelestia:launcherInterrupt

        # --- Caelestia launcher (also on Super+A) ---
        bind = $mainMod, A, global, caelestia:launcher

        # --- Caelestia shell panels ---
        bind = $mainMod, L, global, caelestia:lock
        bind = $mainMod SHIFT, L, global, caelestia:session
        bindl = Ctrl+Alt, C, global, caelestia:clearNotifs

        # --- Brightness (hardware keys → caelestia OSD) ---
        bindl = , XF86MonBrightnessUp, global, caelestia:brightnessUp
        bindl = , XF86MonBrightnessDown, global, caelestia:brightnessDown

        # --- Media (hardware keys → caelestia OSD) ---
        bindl = , XF86AudioPlay, global, caelestia:mediaToggle
        bindl = , XF86AudioPause, global, caelestia:mediaToggle
        bindl = , XF86AudioNext, global, caelestia:mediaNext
        bindl = , XF86AudioPrev, global, caelestia:mediaPrev
        bindl = , XF86AudioStop, global, caelestia:mediaStop

        # --- Screenshots (same keys, caelestia backend) ---
        bind = $mainMod, P, exec, caelestia screenshot
        bind = $mainMod SHIFT, P, global, caelestia:screenshotFreeze
        bind = $mainMod ALT, P, global, caelestia:screenshot
        bindl = , Print, exec, caelestia screenshot

        # --- Recording ---
        bind = $mainMod, R, exec, caelestia record -s
        bind = $mainMod SHIFT, R, exec, caelestia record

        # --- Kill / restart shell ---
        bindr = Ctrl+$mainMod+Shift, R, exec, qs -c caelestia kill
        bindr = Ctrl+$mainMod+Alt, R, exec, qs -c caelestia kill; sleep .1; caelestia shell -d


        # =================================================================
        #   WINDOW ACTIONS (unchanged)
        # =================================================================

        # Close / Kill
        bind = $mainMod SHIFT, Q, exec, dontkillsteam.sh
        bind = ALT, F4, exec, dontkillsteam.sh
        bind = $mainMod, Delete, exit,

        # Float / Fullscreen / Pin
        bind = $mainMod, W, togglefloating,
        bind = $mainMod SHIFT, F, fullscreen, 2
        bind = ALT, Return, pin,

        # Focus movement
        bind = $mainMod, Left, movefocus, l
        bind = $mainMod, Right, movefocus, r
        bind = $mainMod, Up, movefocus, u
        bind = $mainMod, Down, movefocus, d
        bind = ALT, Tab, movefocus, d

        # Split
        bind = $mainMod, J, layoutmsg, togglesplit

        # Window grouping
        bind = $mainMod, T, togglegroup,
        bind = $mainMod SHIFT, T, exec, windowgroup.sh
        binde = $mainMod, code:34, changegroupactive, b
        binde = $mainMod, code:35, changegroupactive, f

        # Resize (held keys)
        binde = $mainMod SHIFT, Right, resizeactive, 30 0
        binde = $mainMod SHIFT, Left, resizeactive, -30 0
        binde = $mainMod SHIFT, Up, resizeactive, 0 -30
        binde = $mainMod SHIFT, Down, resizeactive, 0 30

        # Move active window (floating: pixel offset, tiled: direction)
        binded = $mainMod SHIFT CONTROL, left, Move activewindow to the left, exec, $moveactivewindow -30 0 || hyprctl dispatch movewindow l
        binded = $mainMod SHIFT CONTROL, right, Move activewindow to the right, exec, $moveactivewindow 30 0 || hyprctl dispatch movewindow r
        binded = $mainMod SHIFT CONTROL, up, Move activewindow up, exec, $moveactivewindow 0 -30 || hyprctl dispatch movewindow u
        binded = $mainMod SHIFT CONTROL, down, Move activewindow down, exec, $moveactivewindow 0 30 || hyprctl dispatch movewindow d

        # Mouse bindings
        bindm = $mainMod, mouse:272, movewindow
        bindm = $mainMod, mouse:273, resizewindow
        bindm = $mainMod, Z, movewindow


        # =================================================================
        #   WORKSPACES (unchanged)
        # =================================================================

        # Switch to workspace by number
        bind = $mainMod, 1, workspace, 1
        bind = $mainMod, 2, workspace, 2
        bind = $mainMod, 3, workspace, 3
        bind = $mainMod, 4, workspace, 4
        bind = $mainMod, 5, workspace, 5
        bind = $mainMod, 6, workspace, 6
        bind = $mainMod, 7, workspace, 7
        bind = $mainMod, 8, workspace, 8
        bind = $mainMod, 9, workspace, 9
        bind = $mainMod, 0, workspace, 10

        # Relative workspace switching
        binde = $mainMod CTRL, Right, workspace, r+1
        binde = $mainMod CTRL, Left, workspace, r-1

        # Jump to first empty workspace
        bind = $mainMod CTRL, Down, workspace, empty

        # Scroll through workspaces with mouse wheel
        bind = $mainMod, mouse_down, workspace, e+1
        bind = $mainMod, mouse_up, workspace, e-1

        # Move window to workspace (switches to that workspace)
        bind = $mainMod SHIFT, 1, movetoworkspace, 1
        bind = $mainMod SHIFT, 2, movetoworkspace, 2
        bind = $mainMod SHIFT, 3, movetoworkspace, 3
        bind = $mainMod SHIFT, 4, movetoworkspace, 4
        bind = $mainMod SHIFT, 5, movetoworkspace, 5
        bind = $mainMod SHIFT, 6, movetoworkspace, 6
        bind = $mainMod SHIFT, 7, movetoworkspace, 7
        bind = $mainMod SHIFT, 8, movetoworkspace, 8
        bind = $mainMod SHIFT, 9, movetoworkspace, 9
        bind = $mainMod SHIFT, 0, movetoworkspace, 10

        # Move window to workspace (relative)
        binde = $mainMod CTRL ALT, Right, movetoworkspace, r+1
        binde = $mainMod CTRL ALT, Left, movetoworkspace, r-1

        # Move window to workspace silently (don't switch)
        bind = $mainMod ALT, 1, movetoworkspacesilent, 1
        bind = $mainMod ALT, 2, movetoworkspacesilent, 2
        bind = $mainMod ALT, 3, movetoworkspacesilent, 3
        bind = $mainMod ALT, 4, movetoworkspacesilent, 4
        bind = $mainMod ALT, 5, movetoworkspacesilent, 5
        bind = $mainMod ALT, 6, movetoworkspacesilent, 6
        bind = $mainMod ALT, 7, movetoworkspacesilent, 7
        bind = $mainMod ALT, 8, movetoworkspacesilent, 8
        bind = $mainMod ALT, 9, movetoworkspacesilent, 9
        bind = $mainMod ALT, 0, movetoworkspacesilent, 10

        # Special workspace (scratchpad)
        bind = $mainMod SHIFT, S, movetoworkspacesilent, special
        bind = $mainMod, S, togglespecialworkspace,

        # Move workspace between monitors
        bind = $mainMod ALT, Left, movecurrentworkspacetomonitor, l
        bind = $mainMod ALT, Right, movecurrentworkspacetomonitor, r


        # =================================================================
        #   APPLICATION LAUNCHERS (unchanged)
        # =================================================================

        bind = $mainMod, Return, exec, $terminal
        bind = $mainMod, E, exec, $fileExplorer
        bind = $mainMod, F, exec, $browser
        bind = $mainMod, D, exec, vesktop
        bind = $mainMod, C, exec, kitty --class ai-assistant --title "AI Assistant" -e pi
        bind = $mainMod SHIFT, C, exec, hyprctl dispatch exec "[float on; size 60% 60%; center on] kitty --class ai-assistant --title 'AI Assistant' -e pi"
        bind = CTRL SHIFT, Escape, exec, kitty --class btop --title btop -e btop

        # Quake-style drop-down windows
        bind = $mainMod SHIFT, Return, exec, hyprctl dispatch exec "[float on; size 60% 60%; center on] $terminal"
        bind = $mainMod SHIFT, E, exec, hyprctl dispatch exec "[float on; size 60% 60%; center on] $fileExplorer"

        # DualSense controller config
        bind = $mainMod, X, exec, dualsense.sh

        # Pass-through for OBS
        bind = $mainMod, code:63, pass, class:^(com.obsproject.Studio)$


        # =================================================================
        #   SYSTEM
        # =================================================================

        # Clipboard (same keys, caelestia/fuzzel backend)
        bind = $mainMod, V, exec, pkill fuzzel || caelestia clipboard
        bind = $mainMod SHIFT, V, exec, pkill fuzzel || caelestia clipboard -d

        # Keyboard layout switch
        bind = $mainMod, Space, exec, hyprctl switchxkblayout all next

        # Notification sidebar toggle (was swaync)
        bind = $mainMod, slash, exec, caelestia shell drawers toggle sidebar

        # Night mode toggle (hyprsunset)
        bind = $mainMod, N, exec, pkill hyprsunset || hyprsunset

        # Next wallpaper (via caelestia)
        bind = $mainMod ALT, W, exec, caelestia wallpaper -r

        # Colour picker
        bind = $mainMod SHIFT, slash, exec, hyprpicker -a


        # =================================================================
        #   VOLUME (wpctl — caelestia shows OSD)
        # =================================================================

        bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        bindle = , XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        bindle = , XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    '';
}

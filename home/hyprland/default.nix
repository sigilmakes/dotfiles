# Hyprland — Home Manager configuration entry point
#
# This is the main Hyprland config, managed by Home Manager. It generates
# ~/.config/hypr/hyprland.conf from Nix expressions.
#
# The config is split across sub-modules:
#   - keybindings.nix  — all keyboard/mouse bindings (caelestia global shortcuts)
#   - windowrules.nix  — per-app window rules, layouts, layer rules
#   - animations.nix   — bezier curves and animation definitions
#   - input.nix        — keyboard, mouse, touchpad, gesture settings
#
# Caelestia shell handles: bar, launcher, notifications, lock screen,
# session menu, OSD, idle management, wallpaper, and theming.
# It's started via systemd (see caelestia.nix), not exec-once.

{ config, pkgs, lib, ... }:

{
    imports = [
        ./keybindings.nix
        ./windowrules.nix
        ./animations.nix
        ./input.nix
    ];

    # Machine config is a mutable user file — seed once, then user-owned.
    # Edit ~/.config/hypr/machines/<hostname>.conf for monitors, per-machine
    # binds, etc. without needing a rebuild.
    home.activation.seedMachineConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        machine_dir="${config.xdg.configHome}/hypr/machines"
        machine_file="$machine_dir/${config.home.hostName}.conf"
        if [ ! -f "$machine_file" ] || [ -L "$machine_file" ]; then
            rm -f "$machine_file"
            mkdir -p "$machine_dir"
            cp "${./machines/${config.home.hostName}.conf}" "$machine_file"
            chmod u+w "$machine_file"
            echo "hyprland: seeded ${config.home.hostName}.conf"
        fi
    '';

    # Packages needed by exec-once entries and keybindings
    home.packages = with pkgs; [
        networkmanagerapplet    # nm-applet WiFi/network tray
        hyprsunset              # Night mode / blue light filter (Super+N toggle)
    ];

    wayland.windowManager.hyprland = {
        enable = true;

        # Integrate with systemd — starts Hyprland-related user services
        systemd.enable = true;

        settings = {
            # --- Application launcher variables ---
            # These match the old $term/$file/$browser names used by keybindings.
            "$terminal" = "kitty";
            "$fileExplorer" = "dolphin";
            "$browser" = "firefox";
            "$term" = "kitty";
            "$file" = "dolphin";

            # --- Environment variables ---
            env = [
                "XDG_CURRENT_DESKTOP,Hyprland"
                "XDG_SESSION_TYPE,wayland"
                "XDG_SESSION_DESKTOP,Hyprland"
                "GTK_USE_PORTAL,1"
                "QT_QPA_PLATFORM,wayland;xcb"
                "QT_QPA_PLATFORMTHEME,qt6ct"
                "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
                "QT_AUTO_SCREEN_SCALE_FACTOR,1"
                "MOZ_ENABLE_WAYLAND,1"
                "GDK_SCALE,1"
                "GDK_BACKEND,wayland,x11"
                "SDL_VIDEODRIVER,wayland,x11,windows"
                "CLUTTER_BACKEND,wayland"
                "ELECTRON_OZONE_PLATFORM_HINT,auto"
                "XCURSOR_THEME,Bibata-Modern-Ice"
                "XCURSOR_SIZE,24"
            ];

            # --- Autostart ---
            exec-once = [
                # XDG portal setup
                "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
                "dbus-update-activation-environment --systemd --all"
                "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

                # System services
                "gnome-keyring-daemon --start --components=pkcs11,secrets,ssh"
                "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
                "blueman-applet"
                "nm-applet --indicator"

                # Clipboard manager
                "wl-paste --type text --watch cliphist store"
                "wl-paste --type image --watch cliphist store"

                # Cursor theme for gsettings
                "hyprctl setcursor Bibata-Modern-Ice 24"
                "gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'"
                "gsettings set org.gnome.desktop.interface cursor-size 24"

                # Forward bluetooth media commands to MPRIS
                "mpris-proxy"

                # Caelestia resizer (window auto-resize, e.g. PiP)
                "caelestia resizer -d"

                # Re-apply current scheme on login so user templates (kitty, etc.) are generated
                "sleep 3 && caelestia scheme set -n $(caelestia scheme get -n)"


            ];

            # --- Misc settings ---
            misc = {
                vrr = 0;
                disable_hyprland_logo = true;
                disable_splash_rendering = true;
                force_default_wallpaper = 0;
                enable_swallow = false;
                swallow_regex = "^(kitty)$";
                allow_session_lock_restore = true;
                middle_click_paste = false;
                focus_on_activate = true;
                mouse_move_enables_dpms = true;
                key_press_enables_dpms = true;
            };

            ecosystem = {
                no_donation_nag = true;
            };

            debug = {
                disable_logs = false;
                error_position = 1;
            };
        };

        # Machine-specific source line is in keybindings.nix extraConfig
        # (must come before the submap block).
        extraConfig = "";
    };
}

# Caelestia shell — Quickshell-based desktop shell for Hyprland.
#
# This replaces the entire HyDE rice stack:
#   waybar      → caelestia bar module
#   rofi        → caelestia launcher module
#   swaync      → caelestia notifications + sidebar
#   swaylock    → caelestia lock module
#   wlogout     → caelestia session module
#   wallbash    → caelestia Material You dynamic colour scheme
#   cava        → caelestia audio visualiser (built-in)
#   hypridle    → caelestia idle management (built-in)
#
# shell.json is NOT managed by Home Manager — it's a mutable user file.
# Caelestia watches it for live changes, so you can edit it at runtime.
# A default config is seeded on first activation only.
#
# The CLI (caelestia-cli) handles wallpaper management, colour scheme
# generation, theme switching, screenshots, and screen recording.

{ config, pkgs, lib, ... }:

let
    # Default shell.json — seeded once, then owned by the user.
    defaultConfig = builtins.toJSON {
        appearance = {
            font = {
                family = {
                    sans = "Rubik";
                    mono = "CaskaydiaCove NF";
                    material = "Material Symbols Rounded";
                    clock = "Rubik";
                };
                size.scale = 1;
            };
            rounding.scale = 1;
            spacing.scale = 1;
            padding.scale = 1;
            anim.durations.scale = 1;
            transparency = {
                enabled = false;
                base = 0.85;
                layers = 0.4;
            };
        };

        general = {
            apps = {
                terminal = [ "kitty" ];
                audio = [ "pavucontrol" ];
                playback = [ "mpv" ];
                explorer = [ "dolphin" ];
            };
            idle = {
                lockBeforeSleep = true;
                inhibitWhenAudio = true;
                timeouts = [
                    {
                        timeout = 300;
                        idleAction = "lock";
                    }
                    {
                        timeout = 600;
                        idleAction = "dpms off";
                        returnAction = "dpms on";
                    }
                ];
            };
        };

        background = {
            enabled = true;
            desktopClock.enabled = false;
            visualiser = {
                enabled = false;
                autoHide = true;
            };
        };

        bar = {
            persistent = true;
            showOnHover = true;
            scrollActions = {
                workspaces = true;
                volume = true;
                brightness = true;
            };
            popouts = {
                activeWindow = true;
                statusIcons = true;
                tray = true;
            };
            workspaces = {
                shown = 5;
                activeIndicator = true;
                occupiedBg = false;
                showWindows = true;
                perMonitorWorkspaces = true;
                label = "  ";
                occupiedLabel = "󰮯";
                activeLabel = "󰮯";
            };
            status = {
                showAudio = false;
                showMicrophone = false;
                showKbLayout = false;
                showNetwork = true;
                showWifi = true;
                showBluetooth = true;
                showBattery = false;
                showLockStatus = true;
            };
            clock.showIcon = true;
            entries = [
                { id = "logo"; enabled = true; }
                { id = "workspaces"; enabled = true; }
                { id = "spacer"; enabled = true; }
                { id = "activeWindow"; enabled = true; }
                { id = "spacer"; enabled = true; }
                { id = "tray"; enabled = true; }
                { id = "clock"; enabled = true; }
                { id = "statusIcons"; enabled = true; }
                { id = "power"; enabled = true; }
            ];
        };

        border = {
            rounding = 15;
            thickness = 2;
        };

        dashboard = {
            enabled = true;
            showOnHover = true;
        };

        launcher = {
            maxShown = 7;
            maxWallpapers = 9;
            actionPrefix = ">";
            specialPrefix = "@";
            vimKeybinds = false;
            enableDangerousActions = false;
        };

        notifs = {
            expire = false;
            defaultExpireTimeout = 5000;
            actionOnClick = false;
        };

        osd = {
            enabled = true;
            hideDelay = 2000;
            enableBrightness = true;
            enableMicrophone = false;
        };

        session = {
            enabled = true;
            commands = {
                logout = [ "loginctl" "terminate-user" "" ];
                shutdown = [ "systemctl" "poweroff" ];
                hibernate = [ "systemctl" "hibernate" ];
                reboot = [ "systemctl" "reboot" ];
            };
        };

        sidebar.enabled = true;

        utilities = {
            enabled = true;
            maxToasts = 4;
            toasts = {
                configLoaded = true;
                chargingChanged = true;
                gameModeChanged = true;
                dndChanged = true;
                audioOutputChanged = true;
                audioInputChanged = true;
                capsLockChanged = true;
                numLockChanged = true;
                kbLayoutChanged = true;
                vpnChanged = true;
                nowPlaying = false;
            };
            vpn = {
                enabled = true;
                provider = [];
            };
        };

        services = {
            weatherLocation = "";
            useFahrenheit = false;
            useTwelveHourClock = false;
            gpuType = "amd";
            audioIncrement = 0.1;
            brightnessIncrement = 0.1;
            maxVolume = 1.0;
            smartScheme = true;
            visualiserBars = 45;
        };

        paths = {
            wallpaperDir = "~/Pictures/Wallpapers";
        };
    };
in
{
    programs.caelestia = {
        enable = true;

        # Start via systemd user service (auto-starts with graphical session)
        systemd = {
            enable = true;
            target = "hyprland-session.target";
        };

        # settings is intentionally empty — shell.json is user-managed.
        # The HM module only generates the file when settings != {}.

        # --- CLI ---
        cli.enable = true;
    };

    # Seed shell.json on first activation only.
    # After that it's the user's file — edit freely, caelestia live-reloads.
    home.activation.seedCaelestiaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config_dir="${config.xdg.configHome}/caelestia"
        config_file="$config_dir/shell.json"
        if [ ! -f "$config_file" ] || [ -L "$config_file" ]; then
            # Remove stale symlink from previous HM-managed setup
            rm -f "$config_file"
            mkdir -p "$config_dir"
            echo '${defaultConfig}' > "$config_file"
            echo "caelestia: seeded default shell.json"
        fi
    '';

    # Ensure wallpaper directory exists for caelestia's wallpaper switcher.
    home.file."Pictures/Wallpapers/.keep".text = "";

    # Kitty colour scheme template — caelestia regenerates this on every
    # scheme change via its user template system.
    # Input:  ~/.config/caelestia/templates/kitty.conf
    # Output: ~/.local/state/caelestia/theme/kitty.conf
    xdg.configFile."caelestia/templates/kitty.conf".source = ./apps/kitty/caelestia-kitty.template;

    # --- Additional packages needed by caelestia ---
    home.packages = with pkgs; [
        # Clipboard — caelestia uses fuzzel for clipboard picker
        wl-clipboard            # wl-copy/wl-paste CLI tools for Wayland clipboard
        cliphist                # clipboard history manager
        fuzzel                  # Wayland-native app launcher (used by caelestia clipboard/emoji)

        # Screenshot/recording deps (caelestia has its own screenshot/record commands)
        swappy                  # screenshot editor (caelestia screenshot pipes to this)

        # Media control
        playerctl               # MPRIS media player control

        # Misc tools used by caelestia
        brightnessctl           # screen brightness control
        ddcutil                 # external monitor brightness (DDC/CI)
        lm_sensors              # hardware sensors (CPU/GPU temp)

        # Notification tools
        libnotify               # notify-send

        # Polkit agent (for auth dialogs — needed until caelestia has its own)
        polkit_gnome
    ];
}

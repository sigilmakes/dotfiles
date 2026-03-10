# greetd — minimal display manager for Wayland
#
# greetd is a lightweight login daemon. It runs on TTY1 and presents a
# text-based login screen (tuigreet). After you authenticate, it launches
# your chosen session (Hyprland).
#
# Flow: boot → greetd starts on TTY1 → tuigreet shows login prompt →
#       you log in → Hyprland launches → you're on your desktop.
#
# Why greetd over GDM/SDDM?
#   - It's tiny and fast (no GUI framework dependency)
#   - tuigreet is a clean TUI — no mouse needed, just type and go
#   - Perfect for single-user setups where you just want to get to Hyprland

{ config, pkgs, lib, ... }:

{
    # --- greetd service ---
    services.greetd = {
        enable = true;

        settings = {
            default_session = {
                # tuigreet is the TUI greeter — shows username/password prompt
                # in a nice terminal interface.
                #
                # Flags:
                #   --remember          = pre-fill the last username
                #   --remember-session  = pre-fill the last chosen session
                #   --time              = show clock on the login screen
                #   --cmd               = default session command to launch
                #
                # After login, greetd runs the session command (Hyprland).
                command = ''
                    ${pkgs.tuigreet}/bin/tuigreet \
                        --remember \
                        --remember-session \
                        --time \
                        --cmd Hyprland
                '';

                # Run as the greeter user (not root) for security.
                # greetd creates this user automatically.
                user = "greeter";
            };
        };
    };

    # Delay greetd until all other boot jobs finish.
    # Without this, systemd status messages print over tuigreet on TTY1.
    # Type = "idle" means: wait for everything else, then start.
    systemd.services.greetd.serviceConfig.Type = "idle";

    # Install tuigreet so it's available system-wide
    # (greetd needs it at the system level, not per-user)
    environment.systemPackages = [
        pkgs.tuigreet
    ];
}

# Home Manager — entry point for user-level configuration.
#
# This manages dotfiles, user packages, and per-app configs.
# System-level config (services, kernel, hardware) lives in modules/.
# User-level config (shell, apps, theming) lives here in home/.
#
# CURRIED FUNCTION: flake.nix calls this with per-user AND per-machine config:
#   import ./home { hostname = "gaia"; username = "sigil"; gitName = "..."; gitEmail = "..."; }
#
# hostname determines which machine config gets sourced by Hyprland
# (monitors, machine-specific exec-once entries).
# Each machine needs a matching file at home/hyprland/machines/<hostname>.conf.

{ hostname, username, gitName ? "", gitEmail ? "" }:

{ config, pkgs, lib, inputs, ... }:

{
    # --- Custom options ---
    # Declare options that other modules (like git.nix) can read.
    # These are populated from the curried args passed by flake.nix.
    options.home.hostName = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Machine hostname (selects hyprland machine config)";
    };

    options.home.git = {
        userName = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Git user.name for this user";
        };
        userEmail = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Git user.email for this user";
        };
    };

    # --- Config ---
    config = {
        # --- Home Manager metadata ---
        home.username = username;
        home.homeDirectory = "/home/${username}";

        # This value determines the Home Manager release your configuration is
        # compatible with. Don't change after initial setup.
        home.stateVersion = "25.05";

        # Let Home Manager manage itself (enables the `home-manager` CLI tool)
        programs.home-manager.enable = true;

        # Set per-machine and per-user identity from curried args
        home.hostName = hostname;
        home.git = {
            userName = gitName;
            userEmail = gitEmail;
        };
    };

    # --- Module imports ---
    imports = [
        # Caelestia shell — the Home Manager module from the flake
        inputs.caelestia-shell.homeManagerModules.default

        # Shell
        ./shell/bash.nix
        ./shell/git.nix

        # Hyprland compositor
        ./hyprland/default.nix

        # Caelestia shell configuration
        ./caelestia.nix

        # Theming (clean GTK/Qt, cursor — no wallbash)
        ./theming/default.nix

        # Utility scripts (push-to-talk, aiassistant, dontkillsteam)
        ./scripts/default.nix

        # Apps
        ./apps/kitty.nix
        ./apps/micro.nix
        ./apps/screenshots.nix     # grim, slurp, swappy
        ./apps/yazi.nix
        ./apps/dolphin.nix
        ./apps/firefox
        ./apps/cli-tools.nix
        ./apps/ai.nix
        ./apps/mangohud.nix
        ./apps/sunshine.nix
        ./apps/vesktop.nix
        ./apps/easyeffects.nix
        ./apps/keyring.nix
        ./apps/networking.nix
        ./apps/media.nix
        ./apps/utilities.nix
    ];
}

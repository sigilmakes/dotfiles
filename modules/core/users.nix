# User accounts and nixpkgs settings
#
# Defines user accounts and their group memberships.
# Each group grants access to specific subsystems:
#   wheel         — sudo access
#   networkmanager — manage WiFi/network without root
#   video         — GPU/display access (Hyprland, brightness control)
#   audio         — direct audio device access (usually PipeWire handles this)
#   docker        — run containers without sudo (only needed for root daemon)
#   input         — raw input devices (needed for some Hyprland features)
#
# To add a new user with the same desktop:
#   1. Add a users.users.<name> block here (copy sigil's)
#   2. Add home-manager.users.<name> = import ./home in flake.nix
#   3. Update extraSpecialArgs.username for the new user (or use per-user args)

{ config, pkgs, lib, ... }:

{
    # --- User account ---
    users.users.sigil = {
        isNormalUser = true;    # Creates home dir, sets sensible defaults
        home = "/home/sigil";
        description = "Willow";
        shell = pkgs.bash;

        extraGroups = [
            "wheel"           # sudo access
            "networkmanager"  # manage network connections
            "video"           # GPU and display devices
            "audio"           # audio devices
            # "docker"        # not needed — using rootless Docker (see docker.nix)
            "input"           # raw input devices
        ];
    };

    # --- Nixpkgs settings ---
    # Allow installation of packages with non-free licenses.
    # Needed for: Steam, Discord, some firmware, NVIDIA drivers, etc.
    # Without this, nix will refuse to build/install unfree packages.
    nixpkgs.config.allowUnfree = true;
}

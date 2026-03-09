# Vesktop — Wayland-native Discord client.
#
# Vesktop is an Electron-based Discord client that supports Wayland natively
# (no XWayland). It also includes Vencord for client-side mods/plugins.
#
# Launch flags:
#   --enable-features=UseOzonePlatform --ozone-platform=wayland
# are handled automatically by Vesktop (it detects Wayland).
#
# Discord/Vesktop has a window rule in windowrules.nix for opacity.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        vesktop
    ];
}

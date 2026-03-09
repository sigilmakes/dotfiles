# Steam — Valve's game client and Gamescope compositor
#
# This enables Steam with all the bells and whistles:
# - Gamescope: a micro-compositor that wraps games for better performance,
#   HDR support, and resolution scaling. capSysNice lets it set higher
#   process priorities (helps with frame pacing).
# - Remote Play: opens firewall ports so you can stream games to other
#   devices on your network (Steam Link, phone, etc.)
# - Dedicated Server: opens firewall ports for hosting game servers.
# - Local Network Game Transfers: lets Steam send game files to other
#   Steam installs on your LAN instead of re-downloading.
# - MangoHud: performance overlay (FPS, CPU/GPU temps, frame times).
#   Toggle it in-game with the `mangohud` launch option in Steam.
#
# Based on: hydenix/modules/system/gaming.nix

{ config, pkgs, lib, ... }:

{
    # --- Steam ---
    programs.steam = {
        enable = true;

        # Open firewall ports for Remote Play (streaming to other devices)
        remotePlay.openFirewall = true;

        # Open firewall ports for dedicated game servers
        dedicatedServer.openFirewall = true;

        # Allow Steam to transfer game installs over your local network
        # instead of re-downloading from the internet
        localNetworkGameTransfers.openFirewall = true;

        # Enable launching games in a Gamescope session from Steam's UI.
        # Gamescope is a Valve-made compositor that wraps games for better
        # Wayland/HDR support and lets you run games at different
        # resolutions than your desktop.
        gamescopeSession.enable = true;
    };

    # --- Gamescope ---
    # Also available outside Steam — you can run `gamescope -- game` directly.
    # capSysNice lets Gamescope set real-time scheduling priorities for
    # smoother frame delivery. Safe to enable on desktop systems.
    programs.gamescope = {
        enable = true;
        capSysNice = true;
    };

    # --- Performance overlay ---
    # MangoHud shows FPS, CPU/GPU usage, temperatures, and frame times
    # as an in-game overlay. To use it, add `mangohud %command%` to a
    # game's launch options in Steam, or run `mangohud -- game` directly.
    environment.systemPackages = with pkgs; [
        mangohud
    ];
}

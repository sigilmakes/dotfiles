# Sunshine — self-hosted game streaming server
#
# Sunshine is an open-source implementation of NVIDIA GameStream.
# It captures your desktop/games and streams them to Moonlight clients
# (Steam Deck, phone, tablet, another PC, etc.)
#
# How it works:
# 1. Sunshine runs as a service on this machine and captures the screen
# 2. You connect from a Moonlight client on another device
# 3. First-time pairing requires entering a PIN at https://localhost:47990
#
# The virtual HEADLESS-1 display in monitors.nix is for Sunshine —
# enable it when you want to stream without a physical monitor, or to
# stream at a different resolution than your main display.
#
# Firewall ports:
#   TCP 47984-47990 — Web UI, RTSP, control
#   UDP 47998-48010 — Video/audio streaming, control

{ config, pkgs, lib, ... }:

{
    # --- Sunshine service ---
    # The NixOS module handles:
    # - Installing the package
    # - Setting up the systemd service
    # - Granting CAP_SYS_ADMIN for KMS (kernel-mode) screen capture
    # - Wrapping the binary with the right environment
    services.sunshine = {
        enable = true;

        # Open the firewall ports Sunshine needs for streaming.
        # Without this, Moonlight clients can't discover or connect.
        openFirewall = true;

        # Allow KMS (kernel-mode setting) capture for better performance.
        # This is the fastest capture method — grabs frames directly from
        # the GPU instead of going through the compositor.
        capSysAdmin = true;
    };

    # --- Avahi (mDNS/DNS-SD) ---
    # Sunshine uses mDNS for zero-config discovery on the local network.
    # Without Avahi, Moonlight clients won't auto-discover this machine
    # and you'd have to enter the IP address manually.
    services.avahi = {
        enable = true;

        # Publish this machine's hostname so other devices can find it
        # as "gaia.local" on the network
        publish = {
            enable = true;
            addresses = true;
        };

        # Allow browsing services advertised by other devices too
        nssmdns4 = true;
    };
}

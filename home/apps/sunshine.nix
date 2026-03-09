# Sunshine — game streaming server (user config).
#
# Sunshine is an open-source implementation of NVIDIA's GameStream protocol.
# It lets you stream your desktop or individual games to Moonlight clients
# (phones, tablets, other PCs, Steam Deck, etc.) over your local network.
#
# The Sunshine SERVICE is enabled at the system level (modules/gaming/).
# This module only manages the user-facing config files:
#
# - sunshine.conf — encoder settings, output config
#   Currently set up for NVENC (NVIDIA hardware encoding) with:
#   * nvenc_preset = 1 (fastest encoding, lowest latency)
#   * output_name = 2 (which display to capture)
#   * sw_preset = medium (fallback software encoding quality)
#
# - apps.json — defines what applications appear in Moonlight's app list:
#   * Desktop — streams your full desktop
#   * Steam Big Picture — launches Steam in BPM, closes it on disconnect
#   * Virtual Display — creates a virtual Hyprland monitor for streaming
#     (useful for streaming to a different resolution/device without
#     affecting your main display)
#
# Both files are MUTABLE so you can adjust streaming settings or add
# new apps without rebuilding. Sunshine's web UI (https://localhost:47990)
# also edits these files directly.

{ config, pkgs, lib, ... }:

{
    # --- Sunshine config ---
    # Encoder and output settings. Edit via the web UI or directly.
    # Note: Sunshine's web UI (https://localhost:47990) may overwrite these,
    # which will conflict with the HM-managed symlink. If you need to use
    # the web UI for config, comment out these entries and manage manually.
    xdg.configFile."sunshine/sunshine.conf" = {
        source = ./sunshine/sunshine.conf;
    };

    # --- Application definitions ---
    xdg.configFile."sunshine/apps.json" = {
        source = ./sunshine/apps.json;
    };
}

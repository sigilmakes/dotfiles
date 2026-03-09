# Media production & streaming tools.
#
# OBS Studio is the standard for game streaming and recording on Linux.
# Runs natively on Wayland via the pipewire capture plugin.
#
# Helvum is a GTK patchbay for PipeWire — lets you visually route
# audio between apps, mics, speakers, and virtual devices. Think
# of it as a GUI for `pw-link`. Useful for routing game audio to
# OBS, or splitting mic input.
#
# guvcview is a simple webcam viewer/recorder. Handy for testing
# camera settings before streaming.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        obs-studio                 # Streaming & recording
        obs-studio-plugins.obs-vkcapture  # Vulkan/OpenGL game capture for OBS
        qpwgraph                   # PipeWire patchbay (audio routing GUI)
        guvcview                   # Webcam viewer / recorder
    ];

    # --- lsfg-vk ---
    # Lossless Scaling Frame Generation (Vulkan layer).
    # TODO: Package from https://github.com/PancakeTAS/lsfg-vk
    # Not in nixpkgs — needs a custom derivation or fetchFromGitHub.
    # Requires: vulkan-loader, gtk4, libadwaita, pkgconf
    # Also needs Lossless Scaling from Steam to be installed.
    # For now, install manually:
    #   Download release from GitHub → tar -xvf ... -C ~/.local
}

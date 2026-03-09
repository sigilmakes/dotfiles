# Screenshot tools.
#
# Caelestia shell handles screenshots natively (area picker, capture, swappy).
# grim is kept separately as a standalone Wayland screenshot tool useful
# for scripting and AI agents.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        grim    # screenshot capture tool for Wayland compositors
    ];
}

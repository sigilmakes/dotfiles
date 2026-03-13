# Pear Desktop — YouTube Music desktop app (Electron wrapper).
#
# Formerly th-ch/youtube-music, renamed to pear-devs/pear-desktop.
# Built-in ad blocking, sponsorblock, and plugin support — no need
# for uBlock Origin. Launches as a standalone window.
#
# Window class: com.github.th_ch.youtube_music
# Bound to Super+M via caelestia toggle music (special:music workspace).

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        pear-desktop
    ];
}

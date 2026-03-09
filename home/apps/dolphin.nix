# Dolphin — KDE's graphical file manager.
#
# Dolphin is the GUI file manager, used for drag-and-drop, thumbnails,
# and quick visual browsing. It's the $file variable in the Hyprland
# keybindings (Super+E opens it).
#
# kio-extras provides thumbnail generation, network browsing (SMB, SFTP),
# and archive handling — without it, Dolphin is functional but limited.
#
# Dolphin stores its own config in ~/.local/share/dolphin/ and
# ~/.config/dolphinrc — we don't manage those with Home Manager since
# Dolphin's settings GUI handles them fine.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        kdePackages.dolphin       # KDE file manager (GUI)
        kdePackages.kio-extras    # thumbnails, network browsing, archive support
    ];
}

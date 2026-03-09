# Fonts — system-wide font installation and default font configuration.
#
# Includes fonts required by Caelestia shell (Material Symbols, Rubik,
# CaskaydiaCove NF) plus general-purpose fonts for apps and emoji.

{ config, pkgs, lib, ... }:

{
    fonts.packages = with pkgs; [
        # Nerd Fonts — patched versions with built-in icons
        nerd-fonts.jetbrains-mono      # Terminal font — clean monospace with ligatures
        nerd-fonts.caskaydia-cove      # CaskaydiaCove NF — used by Caelestia shell

        # Caelestia shell requires these
        material-symbols               # Material Symbols Rounded — shell icons
        rubik                          # Rubik — shell UI text and clock

        # Noto — broad Unicode coverage
        noto-fonts                     # Latin, Cyrillic, Greek, and more
        noto-fonts-color-emoji         # Colour emoji
        noto-fonts-cjk-sans           # CJK glyphs

        # UI fonts
        cantarell-fonts                # GNOME UI font
        font-awesome                   # Icon font (some apps use this)
    ];

    fonts.fontconfig.defaultFonts = {
        monospace = [ "CaskaydiaCove Nerd Font" "JetBrainsMono Nerd Font" "Noto Sans Mono" ];
        sansSerif = [ "Rubik" "Cantarell" "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
    };
}

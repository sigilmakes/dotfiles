# Desktop utilities — calculator, notes, disk tools.
#
# Obsidian is an Electron app — Wayland support is handled by the
# ELECTRON_OZONE_PLATFORM_HINT env var set in hyprland/default.nix.
#
# GParted needs polkit for disk operations — polkitkdeauth.sh in
# Hyprland's exec-once provides the auth agent.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        obsidian                   # Markdown knowledge base / notes
        kdePackages.kcalc          # KDE calculator
        gparted                    # Disk partition editor (needs polkit)
        kdePackages.gwenview        # KDE image viewer
        krita                      # Digital painting / image editing
        kdePackages.kolourpaint    # Simple paint program (KDE)
        libreoffice-qt6-fresh      # Office suite (Qt6, latest release)
        kdePackages.okular         # PDF / document viewer
        pavucontrol                # Full PulseAudio volume control GUI
        hyprpicker                 # Wayland color picker (useful for theming)
        kdePackages.filelight      # Disk usage visualizer — treemap view of what's eating space
    ];
}

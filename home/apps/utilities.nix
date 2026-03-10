# Desktop utilities — calculator, notes, disk tools.
#
# Obsidian is an Electron app — Wayland support is handled by the
# ELECTRON_OZONE_PLATFORM_HINT env var set in hyprland/default.nix.
#
# The nixpkgs obsidian package launches via `electron app.asar`, which
# means argv[0] is "electron". Obsidian's CLI feature checks for
# argv[0] == "obsidian" and refuses to enable otherwise. The wrapper
# below uses exec -a to set argv[0] correctly.
#
# GParted needs polkit for disk operations — polkitkdeauth.sh in
# Hyprland's exec-once provides the auth agent.

{ config, pkgs, lib, ... }:

let
    # Use the official Obsidian binary with its bundled Electron.
    # nixpkgs rewraps Obsidian with system Electron, which renames the
    # binary to "electron" and breaks Obsidian's CLI feature. Using the
    # upstream binary keeps argv[0] == "obsidian".
    obsidian-bin = pkgs.callPackage ../packages/obsidian-bin.nix {};
in
{
    home.packages = with pkgs; [
        obsidian-bin               # Markdown knowledge base / notes (official binary, CLI works)
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

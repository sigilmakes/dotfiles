# Theming — GTK/Qt plumbing for Caelestia's dynamic Material You theming.
#
# Caelestia manages colour schemes dynamically at runtime:
#   - GTK:  writes gtk-3.0/gtk.css and gtk-4.0/gtk.css on scheme change
#   - Qt:   writes qt5ct/qt6ct configs and colour palettes on scheme change
#   - Icons: syncs Papirus folder colours to the scheme's primary colour
#
# This module only provides:
#   - Cursor theme (Bibata)
#   - Base GTK theme/icon/font settings (for apps that read settings.ini)
#   - Qt packages (qt6ct, qtwayland — needed for the platform theme to work)
#   - dconf dark mode defaults
#   - Font packages for Caelestia shell
#
# Everything else is caelestia's domain.

{ config, pkgs, lib, ... }:

{
    # --- Cursor theme ---
    home.pointerCursor = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
        gtk.enable = true;
    };

    # --- GTK theming ---
    # Base settings only — caelestia overwrites gtk.css dynamically.
    gtk = {
        enable = true;

        theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
        };

        iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
        };

        font = {
            name = "Rubik";
            size = 11;
        };

        gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = true;
        };
    };

    # --- Qt theming ---
    # We use qt6ct-kde (patched qt6ct that reads KDE .colors files).
    # HM's qt module is disabled — we install qt6ct-kde manually and
    # set the env var ourselves to avoid HM pulling in the unpatched qt6ct.
    qt.enable = false;

    home.packages = with pkgs; [
        # GTK
        adw-gtk3                                # GTK3 theme matching libadwaita
        gtk3                                    # GTK3 toolkit
        gtk4                                    # GTK4 toolkit
        glib                                    # gsettings
        gsettings-desktop-schemas               # Schema defs
        adwaita-icon-theme                      # Fallback icons
        papirus-icon-theme                      # Icon theme

        # Qt (caelestia manages theming via qt6ct + Darkly style)
        qt6ct-kde                               # Patched qt6ct that reads KDE .colors files
        kdePackages.qtbase                      # Qt6 base
        kdePackages.qtwayland                   # Qt6 Wayland
        darkly                                  # Qt6 style engine (used by caelestia)
        darkly-qt5                              # Qt5 style engine
        (lib.lowPrio kdePackages.breeze-icons)  # KDE fallback icons
        kdePackages.qtimageformats              # Extra image formats
        kdePackages.qtsvg                       # SVG support

        # Fonts required by Caelestia shell
        material-symbols                        # Material Symbols Rounded (shell icons)
        rubik                                   # Rubik font (shell UI text)
        nerd-fonts.caskaydia-cove               # CaskaydiaCove NF (shell mono)
    ];

    # Caelestia's apply_gtk overwrites gtk-4.0/gtk.css with dynamic colours.
    # Force so HM doesn't fail on rebuild (caelestia re-applies on next scheme change).
    xdg.configFile."gtk-4.0/gtk.css".force = true;

    # --- Dark mode via dconf/gsettings ---
    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "adw-gtk3-dark";
            icon-theme = "Papirus-Dark";
            font-name = "Rubik 11";
        };
    };
}

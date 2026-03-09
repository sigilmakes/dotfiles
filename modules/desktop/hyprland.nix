# Hyprland — Wayland compositor (system-level)
#
# This enables Hyprland at the NixOS system level and sets up the environment
# for a Wayland desktop session. The actual Hyprland config (keybindings,
# window rules, theming) is in home/hyprland/ managed by Home Manager.
#
# Caelestia shell provides the desktop shell (bar, launcher, notifications,
# lock, session menu, etc.) and is configured in home/caelestia.nix.

{ config, pkgs, lib, ... }:

{
    # --- Hyprland compositor ---
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    # --- XDG Desktop Portals ---
    xdg.portal = {
        enable = true;
        extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
        ];
    };

    # --- Wayland environment variables ---
    environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        GDK_BACKEND = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    # --- Supporting packages ---
    environment.systemPackages = with pkgs; [
        dconf
        polkit_gnome
    ];

    programs.dconf.enable = true;
}

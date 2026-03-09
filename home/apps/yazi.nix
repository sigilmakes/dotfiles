# Yazi — terminal file manager.
#
# Yazi is a fast terminal file manager written in Rust (think ranger, but
# snappier). It supports image previews (in kitty), bulk rename, tabs,
# and a plugin system.
#
# CONFIG FILES:
#   yazi.toml    — Main settings: layout ratios, sort order, opener rules
#   keymap.toml  — All keybindings (376 lines, heavily customised)
#   init.lua     — Adaptive layout: adjusts pane ratios based on terminal width
#   package.toml — Plugin/flavor dependency declarations (currently empty)
#
# The init.lua has breakpoints tuned to Hyprland half/quarter window splits:
#   <40 cols (quarter): file list only
#   <60 cols (half):    tree + file list
#   <110 cols (wide):   tree + file list + preview
#   110+ cols:          full 1:4:3 layout

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        yazi    # terminal file manager (Rust, fast, image previews in kitty)
    ];

    xdg.configFile = {
        # Main settings — layout, sorting, openers, previewers.
        "yazi/yazi.toml" = {
            source = ./yazi/yazi.toml;
        };

        # Keybindings — vim-style navigation, custom shortcuts.
        "yazi/keymap.toml" = {
            source = ./yazi/keymap.toml;
        };

        # Lua init script — adaptive layout based on terminal width.
        "yazi/init.lua" = {
            source = ./yazi/init.lua;
        };

        # Plugin/flavor dependencies (empty for now).
        "yazi/package.toml" = {
            source = ./yazi/package.toml;
        };
    };
}

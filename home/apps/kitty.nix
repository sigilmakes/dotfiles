# Kitty terminal emulator configuration.
#
# Home Manager's programs.kitty module generates ~/.config/kitty/kitty.conf.
# It supports structured settings, keybindings, font config, and extras.
#
# THEMING: Kitty picks up caelestia's colour scheme via theme.conf.
# Run `caelestia-kitty-theme.sh` after changing schemes to regenerate.
# The script is also wired into Hyprland exec-once to run on login.

{ config, pkgs, lib, ... }:

{
    programs.kitty = {
        enable = true;

        # --- Font ---
        # CaskaydiaCove is the Nerd Font patched version of Cascadia Code.
        # "Nerd Font Mono" = monospaced glyphs (icons won't stretch across cells).
        font = {
            name = "CaskaydiaCove Nerd Font Mono";
            size = 9.0;
        };
        # bold/italic/bold-italic are set to "auto" by default in kitty,
        # meaning it derives them from the main font family. No need to
        # specify them explicitly — kitty handles this well.

        # --- Settings ---
        # Each key-value pair becomes a line in kitty.conf.
        # kitty uses snake_case for its config keys.
        settings = {
            # Don't beep on errors or bell characters. Screen flash only.
            enable_audio_bell = "no";

            # Padding between the terminal content and the window edge (in pts).
            # Gives the text some breathing room.
            window_padding_width = 5;

            # Allow programs in the terminal to read/write the system clipboard.
            # Without this, some TUI apps can't copy to or paste from clipboard.
            clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

            # Colours come from caelestia's user template system.
            # Existing terminals get recoloured via ANSI escape sequences
            # written to /dev/pts/* by caelestia (apply_terms).
            # New terminals pick up the include file below.
        };

        # --- Keybindings ---
        # Maps key combos to kitty actions.
        # Setting a key to "" (empty string) unbinds it.
        keybindings = {
            # Disable default ctrl+shift+left/right (conflicts with word-jump in some apps)
            "ctrl+shift+left" = "";
            "ctrl+shift+right" = "";

            # Disable ctrl+i (conflicts with tab in some TUI apps)
            "ctrl+i" = "";

            # Disable ctrl+shift+f2 (edit kitty config — we manage it via nix)
            "ctrl+shift+f2" = "";

            # shift+enter sends escape-enter sequence.
            # Useful in some TUI apps that distinguish enter from shift+enter.
            # \e = escape, \r = carriage return
            "shift+enter" = "send_text all \\e\\r";
        };

        # --- Extra config ---
        # Raw lines appended to kitty.conf for anything not covered above.
        extraConfig = ''
            # Include caelestia-generated colour scheme.
            # Caelestia's user template system regenerates this on every scheme change.
            # Template: ~/.config/caelestia/templates/kitty.conf
            # Output:   ~/.local/state/caelestia/theme/kitty.conf
            include ~/.local/state/caelestia/theme/kitty.conf

            # Uncomment these if you want transparency or borderless windows:
            # background_opacity 0.60
            # hide_window_decorations yes
            # confirm_os_window_close 0
        '';
    };

    # --- Open actions ---
    # Defines how kitty handles file opens (e.g. from `kitten open`).
    # Text files open in micro, images display with icat.
    xdg.configFile."kitty/open-actions.conf".source = ./kitty/open-actions.conf;
}

# Locale, timezone, and keyboard layout
#
# Sets the system to British English with London timezone.
# Console keyboard is UK layout; the Russian layout is available
# but keyboard switching (gb/ru toggle) is handled by Hyprland
# at the session level, not here — see home/hyprland/ for that config.

{ config, pkgs, lib, ... }:

{
    # --- Timezone ---
    time.timeZone = "Europe/London";

    # --- System locale ---
    # en_GB.UTF-8 = British English, UTF-8 encoding
    # This affects date formats (DD/MM/YYYY), currency (£), and spelling
    i18n.defaultLocale = "en_GB.UTF-8";

    # Per-category locale overrides — keeps everything consistently British
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_GB.UTF-8";
        LC_IDENTIFICATION = "en_GB.UTF-8";
        LC_MEASUREMENT = "en_GB.UTF-8";
        LC_MONETARY = "en_GB.UTF-8";
        LC_NAME = "en_GB.UTF-8";
        LC_NUMERIC = "en_GB.UTF-8";
        LC_PAPER = "en_GB.UTF-8";
        LC_TELEPHONE = "en_GB.UTF-8";
        LC_TIME = "en_GB.UTF-8";
    };

    # --- Console keyboard ---
    # 'uk' is the console keymap name for British layout (yes, it's confusing —
    # Xorg/Wayland call it 'gb', the Linux console calls it 'uk')
    console.keyMap = "uk";

    # --- X/Wayland keyboard ---
    # Sets the default keyboard layout for X11 and Wayland compositors.
    # We define both gb and ru here, but the actual layout switching
    # (keybind to toggle between them) is configured in Hyprland.
    services.xserver.xkb = {
        layout = "gb,ru";
        # options = "grp:alt_shift_toggle";  # Uncomment for X11 switching
        # (Hyprland handles this via input config — see home/hyprland/)
    };
}

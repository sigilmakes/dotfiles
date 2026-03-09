# Bluetooth configuration
#
# Enables Bluetooth hardware and the Blueman GUI for managing devices.
# Blueman provides a system tray icon for quick access to pairing,
# connecting headphones, controllers, etc.

{ config, pkgs, lib, ... }:

{
    # Enable the Bluetooth stack (BlueZ).
    # This handles device discovery, pairing, and connections.
    hardware.bluetooth = {
        enable = true;

        # Turn Bluetooth on automatically at boot.
        # Set to false if you prefer to enable it manually via Blueman
        # to save a tiny bit of power.
        powerOnBoot = true;
    };

    # Blueman — a GTK Bluetooth manager with a system tray applet.
    # Gives you a tray icon for quick pairing/connecting without
    # needing to use `bluetoothctl` in a terminal.
    # The applet auto-starts in Hyprland via the exec-once config.
    services.blueman.enable = true;
}

# DualSense — Sony PS5 controller support
#
# The DualSense (PS5 controller) works as a basic gamepad out of the box
# via the kernel's hid-playstation driver. But for advanced features
# (adaptive triggers, haptics, LED control), you need dualsensectl.
#
# The dualsense.sh script from the Hyprland scripts package uses
# dualsensectl to manage controller settings (LED color, battery
# monitoring, etc.)
#
# Connection methods:
# - USB: plug in and go
# - Bluetooth: pair via `bluetoothctl` or Blueman (hold PS + Share
#   until the light bar blinks to enter pairing mode)
#
# The udev rules below give non-root users access to the controller's
# HID interface, which dualsensectl needs to send commands.

{ config, pkgs, lib, ... }:

{
    # --- DualSense tools ---
    environment.systemPackages = with pkgs; [
        dualsensectl    # CLI tool for DualSense features (LEDs, haptics, battery)
    ];

    # --- udev rules ---
    # Without these, only root can send HID commands to the controller.
    # The rules grant access to users in the "input" group (which
    # sigil is already in — see users.nix).
    services.udev.extraRules = ''
        # Sony DualSense (USB) — vendor 054c, product 0ce6
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"

        # Sony DualSense Edge (USB) — vendor 054c, product 0df2
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"

        # Sony DualSense (Bluetooth)
        SUBSYSTEM=="hidraw", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"

        # Sony DualSense Edge (Bluetooth)
        SUBSYSTEM=="hidraw", KERNELS=="*054C:0DF2*", MODE="0660", TAG+="uaccess"
    '';
}

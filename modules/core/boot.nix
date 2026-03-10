# Boot configuration — systemd-boot on UEFI with latest kernel
#
# We use the latest kernel because the AMD Strix Halo APU (Ryzen AI Max+ 395)
# needs kernel 6.15+ for proper amdgpu support (constant fixes for gfx1151).
# The newer the kernel, the better — stability fixes, performance improvements,
# and firmware support all land in newer versions. nixos-unstable tracks this
# for us, and linuxPackages_latest ensures we always get the newest available.
# Latest linux-firmware is also critical — see hardware.firmware below.
#
# AMD microcode updates patch CPU firmware at boot — important for stability
# and security fixes on Zen 5.

{ config, pkgs, lib, ... }:

{
    # --- Bootloader ---
    # systemd-boot is the modern UEFI bootloader. Simpler than GRUB,
    # works well with NixOS's generation system (each rebuild = a menu entry).
    boot.loader.systemd-boot.enable = true;

    # Allow the bootloader to write to EFI variables (needed for first install)
    boot.loader.efi.canTouchEfiVariables = true;

    # Limit boot menu entries so the EFI partition doesn't fill up
    # NixOS creates a new entry on every rebuild — 10 is plenty for rollback
    boot.loader.systemd-boot.configurationLimit = 10;

    # --- Kernel ---
    # Latest kernel package set — ensures Strix Halo compatibility
    # (GPU, NPU, USB4/Thunderbolt, WiFi 7 all need recent kernel support)
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # --- Firmware ---
    # Latest linux-firmware is critical for Strix Halo stability.
    # The amdgpu driver pulls firmware blobs from this package at boot —
    # newer firmware = fewer GPU hangs and better performance.
    hardware.firmware = [ pkgs.linux-firmware ];

    # --- CPU microcode ---
    # Loads AMD CPU microcode updates early in boot.
    # These are stability/security patches for the CPU itself.
    hardware.cpu.amd.updateMicrocode = true;

    # --- Silent boot ---
    # Suppress kernel and systemd messages on the console so they don't
    # clobber greetd/tuigreet on TTY1. Everything is still in `dmesg`
    # and `journalctl` — this only hides the live console output.
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [ "quiet" "udev.log_level=3" ];

    # --- zram swap ---
    # Compressed swap in RAM — no disk I/O, basically free.
    # With 128GB RAM this is pure safety net: if GTT is loaded with a
    # large LLM model and you're also running a browser + game, the
    # kernel can compress inactive pages instead of OOM-killing.
    # Defaults to 50% of RAM (~64GB usable compressed swap).
    zramSwap.enable = true;
}

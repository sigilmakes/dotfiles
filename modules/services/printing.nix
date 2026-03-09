# Printing — CUPS print server with autodiscovery.
#
# CUPS handles printer management, queue, and drivers.
# Avahi (already enabled by sunshine.nix) provides mDNS/DNS-SD
# so network printers are auto-discovered.
#
# After boot, add printers via:
#   - system-config-printer (GUI) — launch from rofi
#   - http://localhost:631 (CUPS web UI)
#   - lpadmin (CLI)
#
# Most modern printers work driverless via IPP Everywhere (the
# cups-filters package handles this). For older printers, you may
# need to add specific driver packages to services.printing.drivers.

{ config, pkgs, lib, ... }:

{
    # --- CUPS print service ---
    services.printing = {
        enable = true;

        # Drivers for non-IPP printers. Add as needed:
        #   pkgs.gutenprint       — wide printer support
        #   pkgs.hplip            — HP printers
        #   pkgs.brlaser          — Brother laser printers
        drivers = with pkgs; [
            gutenprint             # Broad printer driver collection
        ];
    };

    # --- Printer management GUI ---
    environment.systemPackages = with pkgs; [
        system-config-printer      # GTK printer setup tool
    ];
}

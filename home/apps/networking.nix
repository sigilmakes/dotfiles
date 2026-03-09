# Networking apps — VPN and torrents.
#
# ProtonVPN is a privacy-focused VPN with a GTK GUI. On nyx it
# autostarts via the machine config. On gaia, launch from rofi.
#
# qBittorrent is a Qt-based BitTorrent client. Integrates with
# the Qt/Kvantum theming from our theming modules.
#
# firewall-config is the GUI for firewalld (system firewall).
# Needs polkit for privilege escalation — already handled by
# polkitkdeauth.sh in Hyprland's exec-once.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        protonvpn-gui              # ProtonVPN GTK client
        qbittorrent                # BitTorrent client (Qt)
        firewalld-gui              # firewalld GUI
    ];
}

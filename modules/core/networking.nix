# Networking — NetworkManager with firewall
#
# NetworkManager handles WiFi, Ethernet, and VPN connections.
# It's what most desktop Linux distros use — integrates with
# nm-applet in the system tray for a GUI.
#
# WiFi 7 (MediaTek MT7925) works out of the box via NetworkManager
# on recent kernels. No extra drivers needed.

{ config, pkgs, lib, ... }:

{
    # --- NetworkManager ---
    # Desktop-friendly network management. Handles WiFi, Ethernet,
    # VPN connections, and automatic switching between them.
    # The 'networkmanager' group (added to willow's groups in users.nix)
    # lets non-root users control connections.
    networking.networkmanager.enable = true;

    # --- Firewall (firewalld) ---
    # We use firewalld instead of NixOS's built-in nftables firewall.
    # firewalld gives us:
    #   - Zone-based rules (public, home, trusted, etc.)
    #   - D-Bus interface (apps can request ports via polkit)
    #   - Runtime vs permanent config (test rules before committing)
    #   - firewall-config GUI for easy management
    #   - NetworkManager integration (auto-assigns zones to interfaces)
    #
    # Default zone is "public" — only SSH and DHCPv6 allowed inbound.
    # Steam Remote Play, Sunshine, etc. open their own ports via their
    # NixOS modules (networking.firewall.allowedTCPPorts still works
    # alongside firewalld for NixOS-managed services).
    #
    # GUI: launch `firewall-config` from the app launcher for graphical management.
    # CLI: `firewall-cmd --list-all` to see current rules.

    # Keep NixOS firewall enabled — firewalld acts as the backend.
    # NixOS auto-detects that firewalld is active and routes all
    # networking.firewall.allowedTCPPorts / openFirewall = true
    # declarations through firewalld instead of raw iptables/nftables.
    networking.firewall.enable = true;

    # firewalld requires nftables as its backend
    networking.nftables.enable = true;

    # Enable firewalld as the firewall backend
    services.firewalld.enable = true;
}

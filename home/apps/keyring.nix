# GNOME Keyring — secret storage and SSH agent.
#
# Provides the Secret Service D-Bus API that apps like ProtonVPN, Firefox,
# Git credential helpers, etc. use to store passwords securely.
#
# Components:
#   - secrets: encrypted password/token storage (libsecret/Secret Service)
#   - ssh-agent: manages SSH keys so you don't re-enter passphrases
#   - pkcs11: smart card / certificate support
#
# Seahorse is the GUI for browsing and managing stored secrets.
#
# The keyring daemon is started by Hyprland's exec-once (see hyprland config).
# It needs to run before any app that uses Secret Service (browsers, VPNs, etc).

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        gnome-keyring              # Secret storage daemon + SSH agent
        seahorse                   # GUI for managing stored passwords and keys
        libsecret                  # CLI tools (secret-tool) for scripting keyring access
    ];

    # Tell SSH to use gnome-keyring's agent instead of ssh-agent.
    # Uses $UID via the XDG runtime dir so it works for any user, not just UID 1000.
    home.sessionVariables = {
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    };
}

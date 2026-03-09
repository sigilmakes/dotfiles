# SSH — server and agent configuration
#
# Enables the OpenSSH daemon for remote access, locked down to
# key-based authentication only (no passwords, no root login).
#
# The SSH agent runs as a systemd user service so your keys are
# available to all terminals without manually running ssh-agent.

{ config, pkgs, lib, ... }:

{
    # --- SSH daemon ---
    # Listens on port 22 by default. Lets you SSH into this machine.
    services.openssh = {
        enable = true;

        settings = {
            # Don't allow root to log in via SSH — use willow + sudo instead
            PermitRootLogin = "no";

            # Keys only, no password guessing. You need to put your public key
            # in ~/.ssh/authorized_keys (or use home-manager to manage it)
            PasswordAuthentication = false;

            # Also disable keyboard-interactive auth (another password vector)
            KbdInteractiveAuthentication = false;
        };
    };

    # --- SSH agent ---
    # Runs ssh-agent as a systemd user service. This means your SSH keys
    # are unlocked once per session and available everywhere — no need to
    # run `eval $(ssh-agent)` or `ssh-add` in every terminal.
    programs.ssh.startAgent = true;
}

# Docker — rootless container runtime
#
# Rootless Docker runs the daemon and containers entirely under your
# user account — no root privileges, no setuid, no docker group needed.
# Containers can't escalate to root even if they escape the sandbox.
#
# HOW IT WORKS:
# Instead of a system-wide dockerd running as root, each user gets their
# own dockerd running in a user namespace. The docker socket lives at
# $XDG_RUNTIME_DIR/docker.sock instead of /var/run/docker.sock.
#
# TRADE-OFFS:
# - Can't bind to ports below 1024 (use ports ≥1024 or set CAP_NET_BIND)
# - No native --privileged support (rarely needed for dev work)
# - Slightly more overhead from user namespace remapping
# - cgroup v2 required (NixOS uses this by default)
#
# Common commands work the same:
#   docker ps          — list running containers
#   docker compose up  — start a docker-compose project
#   docker system df   — check disk usage

{ config, pkgs, lib, ... }:

{
    # --- Rootless Docker ---
    # Runs the Docker daemon as a user service — no root, no docker group.
    virtualisation.docker.rootless = {
        enable = true;

        # Set DOCKER_HOST so the CLI finds the rootless socket automatically.
        # Without this, you'd need to pass --host on every command.
        setSocketVariable = true;
    };

    # Don't enable the root daemon — rootless replaces it.
    # If you ever need the root daemon alongside rootless, set this to true
    # and add your user to the "docker" group in users.nix.
    virtualisation.docker.enable = false;
}

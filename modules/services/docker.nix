# Docker — container runtime (rootful)
#
# Runs the standard Docker daemon as root. Containers have full access
# to system resources (bind any port, use --privileged, etc.).
#
# Users in the "docker" group can use the CLI without sudo.
# The docker group is effectively root-equivalent — only add trusted users.
#
# Common commands:
#   docker ps          — list running containers
#   docker compose up  — start a docker-compose project
#   docker system df   — check disk usage

{ config, pkgs, lib, ... }:

{
    virtualisation.docker.enable = true;

    # Add sigil to the docker group so the CLI works without sudo.
    users.users.sigil.extraGroups = [ "docker" ];
}

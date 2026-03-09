# AI tools — Pi coding agent and other AI CLIs.
#
# Pi and nanobot update frequently and benefit from their native package
# managers rather than being pinned to Nix derivations with fixed hashes.
#
# NixOS doesn't allow `npm install -g` to the Nix store, so we set
# NPM_CONFIG_PREFIX to ~/.npm-global — a writable directory outside Nix's
# control. Same pattern for pip via ~/.local.
#
# INSTALL (one-time, after first nixos-rebuild):
#   npm install -g @mariozechner/pi-coding-agent
#
# UPDATE:
#   npm update -g @mariozechner/pi-coding-agent

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        nodejs   # Node.js runtime — provides node + npm + npx
        python3  # Python runtime — provides python + pip
        uv       # Fast Python package/tool installer (also does pipx-style isolated installs via `uv tool install`)
    ];

    # Point npm global installs to a writable directory.
    # Without this, `npm install -g` fails on NixOS because the default
    # prefix is inside the read-only Nix store.
    home.sessionVariables = {
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    # Add npm global bin to PATH so `pi` and other globally-installed
    # npm packages are found.
    home.sessionPath = [
        "$HOME/.npm-global/bin"
    ];
}

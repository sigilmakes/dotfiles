# XIVLauncher-RB — Custom FFXIV launcher with RB patches.
#
# This is the rankynbass fork of XIVLauncher.Core, which adds:
#   - Proton support (use Steam Runtime with Proton)
#   - Wine and DXVK version switcher
#   - Automatic DLSS support (with Proton or nvapi)
#   - Auto-start other Windows programs alongside FFXIV
#   - Dalamud plugin framework
#
# The package comes from a separate flake (drakon64/nixos-xivlauncher-rb)
# added as an input in flake.nix. The NixOS module makes `xivlauncher-rb`
# available as a system package.
#
# Config lives in ~/.xlcore/ — launcher.ini, dalamud configs, wine prefix.
# This module just installs the launcher; config is managed by the launcher
# itself (not declarative).
#
# GameMode support is enabled so FFXIV can use Feral gamemode for
# performance tuning during gameplay.

{ config, pkgs, lib, inputs, ... }:

{
    environment.systemPackages = [
        (inputs.nixos-xivlauncher-rb.packages.${pkgs.stdenv.hostPlatform.system}.xivlauncher-rb.override {
            useGameMode = true;
        })
    ];
}

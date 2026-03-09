# Gamemode — Feral Interactive's performance optimizer
#
# When a game starts (and requests it), gamemode temporarily tweaks
# system settings for better performance:
# - Sets the CPU governor to "performance" (max clock speeds)
# - Adjusts GPU power states
# - Changes I/O scheduler priority
# - Disables screen compositing effects (less relevant on Wayland)
#
# Games can activate it via the gamemode library, or you can wrap
# any process with `gamemoderun ./some-game`.
#
# The gamemode.sh script from the Hyprland scripts package integrates
# with this — it can detect when gamemode is active and adjust
# Hyprland settings (disable animations, change power profile, etc.)

{ config, pkgs, lib, ... }:

{
    # Installs the gamemode daemon and client library.
    # Games that support gamemode will auto-detect it.
    # You can also manually wrap commands: gamemoderun %command%
    programs.gamemode.enable = true;
}

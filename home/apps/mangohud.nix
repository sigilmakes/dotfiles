# MangoHud — in-game performance overlay configuration.
#
# MangoHud displays real-time stats (FPS, CPU/GPU temps, frame times, etc.)
# as an overlay inside games. Toggle it by adding `mangohud %command%` to
# a game's Steam launch options, or run `mangohud -- game` directly.
#
# The MangoHud PACKAGE is installed system-wide in modules/gaming/steam.nix.
# This module only manages the user config file that controls what the
# overlay shows and how it looks.
#
# CONFIG FILE: The full config with all commented options is stored at
# home/apps/mangohud/MangoHud.conf. It includes every available setting
# with documentation comments — uncomment what you want to enable.
# Active by default: gpu_stats, gpu_temp, gpu_core_clock, gpu_power,
# cpu_stats, cpu_temp, cpu_power, fps, frametime, throttling_status,
# frame_timing, text_outline.
#
# The file is placed as MUTABLE so you can tweak it at runtime without
# rebuilding. Changes persist until the next `home-manager switch`, which
# resets it to the version checked into this repo.

{ config, pkgs, lib, ... }:

{
    # MangoHud config — controls what the overlay shows and how it looks.
    # Edit via `mangohud --config` or rebuild to reset.
    xdg.configFile."MangoHud/MangoHud.conf" = {
        source = ./mangohud/MangoHud.conf;
    };
}

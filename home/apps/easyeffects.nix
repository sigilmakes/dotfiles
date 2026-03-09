# EasyEffects — audio processing and equalisation.
#
# EasyEffects is a GTK4 app that sits between PipeWire and your audio
# output, letting you apply effects like:
#   - Parametric EQ (tune headphones/speakers)
#   - Compressor / limiter (normalize loud/quiet audio)
#   - Bass enhancer, exciter, reverb
#   - Noise reduction (for mic input)
#
# It works with PipeWire (configured in modules/desktop/audio.nix).
# Previously installed as a Flatpak on nyx — here it's a native package.
#
# Presets are stored in ~/.config/easyeffects/output/ and can be
# imported/exported from the UI.

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        easyeffects
    ];
}

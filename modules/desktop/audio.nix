# Audio — PipeWire replaces PulseAudio as the sound server.
#
# PipeWire handles audio (and screen sharing) with lower latency than PulseAudio.
# It also speaks PulseAudio's protocol, so all existing apps work without changes.
# The 32-bit ALSA support is there for Steam/Wine/Proton (they need it for game audio).
#
# rtkit lets PipeWire request realtime scheduling from the kernel, which prevents
# audio crackling/dropouts under CPU load (e.g. during gaming or compilation).

{ config, pkgs, lib, ... }:

{
    # --- PipeWire (modern audio server) ---

    # Main PipeWire daemon — manages all audio routing
    services.pipewire.enable = true;

    # ALSA compatibility — many apps and games talk directly to ALSA
    services.pipewire.alsa.enable = true;

    # 32-bit ALSA support — required for Steam, Wine, and most Proton games
    services.pipewire.alsa.support32Bit = true;

    # PulseAudio protocol support — apps that expect PulseAudio (Spotify,
    # Discord, browsers, etc.) connect through this compatibility layer
    services.pipewire.pulse.enable = true;

    # WirePlumber — the session manager that decides which app connects where
    # (e.g. routing audio to headphones vs speakers, handling Bluetooth audio)
    services.pipewire.wireplumber.enable = true;

    # --- Disable PulseAudio ---
    # PipeWire fully replaces it. Having both enabled causes conflicts.
    services.pulseaudio.enable = false;

    # --- Realtime scheduling ---
    # rtkit (RealtimeKit) is a D-Bus service that gives PipeWire permission
    # to use realtime CPU scheduling. Without this, audio can glitch when the
    # system is under heavy load (compiling, gaming, etc.)
    security.rtkit.enable = true;
}

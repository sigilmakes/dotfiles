# Utility scripts — small set of custom scripts that Caelestia doesn't replace.
#
# push-to-talk.sh             — whisper-cpp voice transcription (bound in gaia.conf)
# aiassistant.sh              — launch AI assistant in kitty terminal
# dontkillsteam.sh            — close window, but minimize Steam instead of killing it
# dualsense.sh                — DualSense controller config menu (triggers, touchpad)
# windowgroup.sh              — toggle focused window in/out of a group
# nightmode.sh                — toggle hyprsunset night mode on/off
# nightmode.py                — location-aware night mode daemon (Warrington, UK)


{ config, pkgs, lib, ... }:

let
    runtimeDeps = with pkgs; [
        coreutils
        bash
        procps
        jq
        libnotify
        kitty
        wtype
        alsa-utils
        whisper-cpp-vulkan
        xdotool
        hyprland
        fuzzel
        dualsensectl
    ];

    scripts = pkgs.stdenv.mkDerivation {
        pname = "gaia-scripts";
        version = "0.1.0";
        src = ./src;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        dontBuild = true;

        installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            for script in *.sh; do
                install -Dm755 "$script" "$out/bin/$script"
            done
            for script in *.py; do
                install -Dm755 "$script" "$out/bin/$script"
            done
            runHook postInstall
        '';

        postFixup = ''
            for script in $out/bin/*.sh; do
                wrapProgram "$script" \
                    --prefix PATH : "${lib.makeBinPath runtimeDeps}"
            done
            for script in $out/bin/*.py; do
                wrapProgram "$script" \
                    --prefix PATH : "${lib.makeBinPath runtimeDeps}"
            done
        '';
    };
in
{
    home.packages = [ scripts ];
}

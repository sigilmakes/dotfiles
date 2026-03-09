# Game launchers — PrismLauncher (Minecraft) and Lutris (multi-platform).
#
# PrismLauncher is a Minecraft launcher with multi-instance support.
# It needs a Java runtime — we install the JDK so modded Minecraft
# can compile mods at runtime if needed.
#
# Lutris is a game manager that handles Wine/Proton prefixes,
# runners, and install scripts for non-Steam games (GOG, Epic, etc.)
# It needs Wine and Winetricks for Windows game support.
#
# Protontricks and ProtonUp-Qt are Steam Proton helpers:
# - protontricks: per-game Proton prefix tweaking (winetricks for Proton)
# - protonup-qt: GUI manager for Proton-GE and Wine-GE versions

{ config, pkgs, lib, ... }:

{
    environment.systemPackages = with pkgs; [
        # --- Minecraft ---
        prismlauncher              # Multi-instance Minecraft launcher
        temurin-jre-bin-21         # Java runtime for Minecraft

        # --- Lutris + Wine stack ---
        lutris                     # Game manager (GOG, Epic, Wine games)
        wine64Packages.stagingFull # Wine Staging (64-bit, full feature set)
        winetricks                 # Wine prefix helper (install .NET, vcrun, etc.)

        # --- Proton tools ---
        protontricks               # Winetricks for Steam Proton prefixes
        protonup-qt                # Proton-GE / Wine-GE version manager

        # --- Emulators ---
        rpcs3                      # PS3 emulator
        pcsx2                      # PS2 emulator

        # --- Open-source engines ---
        openmw                     # Morrowind engine reimplementation
    ];
}

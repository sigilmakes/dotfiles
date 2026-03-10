# Gaia — Minisforum MS-S1 MAX, AMD Ryzen AI Max+ 395
#
# This is the top-level NixOS configuration for Gaia. It pulls together
# hardware-specific settings and shared modules to build the full system.
#
# To build:  sudo nixos-rebuild switch --flake .#gaia
# To test:   sudo nixos-rebuild test --flake .#gaia

{ config, pkgs, lib, ... }:

{
    imports = [
        # Hardware-specific config (generated on the actual machine)
        ./hardware.nix

        # --- Core system modules ---
        ../../modules/core/boot.nix        # Bootloader + kernel
        ../../modules/core/networking.nix   # NetworkManager + firewall
        ../../modules/core/users.nix        # User accounts + groups
        ../../modules/core/locale.nix       # Timezone, language, keyboard

        # --- Hardware modules ---
        ../../modules/hardware/gpu-amd.nix  # AMD GPU (RADV + AMDVLK + Mesa)
        # ../../modules/hardware/rocm.nix     # ROCm compute (llama.cpp, ML/AI) + rocm-smi for btop GPU monitoring
        ../../modules/hardware/bluetooth.nix # Bluetooth + Blueman
        ../../modules/hardware/powercap.nix  # RAPL energy counters readable without sudo

        # --- Desktop modules ---
        ../../modules/desktop/hyprland.nix  # Hyprland compositor + Wayland env
        ../../modules/desktop/greetd.nix    # Login screen (tuigreet)
        ../../modules/desktop/audio.nix     # PipeWire audio stack
        ../../modules/desktop/fonts.nix     # Fonts for Hyprland rice

        # --- Gaming ---
        ../../modules/gaming/steam.nix      # Steam + Gamescope + MangoHud
        ../../modules/gaming/gamemode.nix   # Feral gamemode (performance tuning)
        ../../modules/gaming/sunshine.nix   # Game streaming server (Moonlight)
        ../../modules/gaming/dualsense.nix  # PS5 controller support
        ../../modules/gaming/launchers.nix  # PrismLauncher, Lutris, Wine, Protontricks
        ../../modules/gaming/xivlauncher.nix # XIVLauncher-RB (FFXIV)

        # --- Services ---
        ../../modules/services/ssh.nix      # SSH daemon (keys only)
        ../../modules/services/docker.nix   # Container runtime (rootless)
        ../../modules/services/printing.nix # CUPS printing
        ../../modules/services/ollama.nix   # Local LLM inference (ROCm)
    ];

    # Hostname for this machine — used by networking, Avahi, etc.
    networking.hostName = "gaia";

    # gpu-screen-recorder — used by caelestia for screen recording.
    # The NixOS module gives gsr-kms-server the right capabilities
    # so recording works without sudo.
    programs.gpu-screen-recorder.enable = true;

    # --- Nix settings ---
    # Enable flakes and the modern nix CLI
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Automatic garbage collection — cleans old generations weekly.
    # Without this, every `nixos-rebuild` leaves old generations in the
    # Nix store, and disk usage grows forever.
    nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
    };

    # Deduplicate identical files in the Nix store
    nix.settings.auto-optimise-store = true;

    # WARNING: Do not change this after install! It tells NixOS which version
    # of state schema your system was originally installed with. Changing it
    # can break things. It does NOT control which packages you get — that's
    # determined by your flake inputs (nixpkgs).
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "25.05";
}

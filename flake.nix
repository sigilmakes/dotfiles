{
    description = "Gaia — NixOS configuration for Willow's desktop";

    # Enable flakes and the new nix CLI for anyone building this flake.
    # Without this, users need to have flakes enabled in their global nix config.
    nixConfig = {
        experimental-features = [ "nix-command" "flakes" ];
    };

    inputs = {
        # Using unstable for latest kernel support (Strix Halo needs 6.15+)
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # XIVLauncher-RB — FFXIV launcher with RB patches (Dalamud, Wine/DXVK switcher)
        nixos-xivlauncher-rb = {
            url = "github:drakon64/nixos-xivlauncher-rb";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # nix-strix-halo — pre-built ROCm + llama.cpp for Strix Halo (gfx1151)
        # Provides ROCm 7 TheRock nightly binaries and llama.cpp with rocWMMA
        # support without requiring a system-wide ROCm installation.
        # NOT following nixpkgs — this flake bundles its own pinned ROCm
        # binaries from TheRock nightlies, independent of nixpkgs versions.
        nix-strix-halo = {
            url = "github:hellas-ai/nix-strix-halo";
        };

        # Caelestia shell — Quickshell-based desktop shell for Hyprland.
        # Replaces waybar, rofi, swaync, swaylock, wlogout with a unified
        # QML shell that handles bar, launcher, notifications, lock screen,
        # session menu, OSD, dashboard, and Material You dynamic theming.
        caelestia-shell = {
            url = "github:caelestia-dots/shell";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, ... }@inputs: {
        nixosConfigurations = {

            # Gaia — Minisforum MS-S1 MAX (AMD Strix Halo)
            gaia = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit inputs; };
                modules = [
                    # qt6ct-kde: patches qt6ct to read KDE .colors files
                    { nixpkgs.overlays = [ (import ./overlays/qt6ct-kde.nix) ]; }

                    ./hosts/gaia

                    home-manager.nixosModules.home-manager
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.extraSpecialArgs = { inherit inputs; };

                        # Each user gets the full rice with their own identity.
                        # To add a second user:
                        #   1. Add users.users.<name> in modules/core/users.nix
                        #   2. Add home-manager.users.<name> below with their details
                        home-manager.users.sigil = import ./home {
                            hostname = "gaia";
                            username = "sigil";
                            gitName = "Willow Sparks";
                            gitEmail = "willow.sparks002@gmail.com";
                        };
                    }
                ];
            };

            # Future: Athena — work laptop
            # athena = nixpkgs.lib.nixosSystem { ... };
        };
    };
}

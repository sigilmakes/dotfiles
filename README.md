# dotfiles

NixOS flake for **Gaia** — a Minisforum MS-S1 MAX desktop (Ryzen AI Max+ 395 / Radeon 8060S / 128GB LPDDR5X). Hyprland + [Caelestia](https://github.com/caelestia-dots/shell) shell, fully declarative.

## What's in here

```
flake.nix                    # Entry point — nixpkgs, home-manager, caelestia, nix-strix-halo
hosts/gaia/                  # Machine config + hardware
modules/
  core/                      # Boot, locale, networking, users
  desktop/                   # Hyprland, greetd, PipeWire, fonts
  hardware/                  # AMD GPU (RADV), ROCm (gfx1151), Bluetooth
  gaming/                    # Steam, Lutris, XIVLauncher, DualSense, Sunshine
  services/                  # Docker, CUPS, SSH
home/
  caelestia.nix              # Caelestia shell (bar, launcher, notifications, lock, session)
  hyprland/                  # Keybindings, window rules, animations, per-machine monitors
  theming/                   # GTK/Qt, cursor, wallpaper
  apps/                      # Firefox, kitty, micro, yazi, btop, MangoHud, OBS, ...
  shell/                     # Bash, git
  scripts/                   # ~50 shell scripts (volume, brightness, theming, etc.)
```

## Install

Boot a NixOS minimal ISO, connect to the network, then:

```bash
git clone https://github.com/sigilmakes/dotfiles.git
cd dotfiles
bash install.sh
```

The installer handles disk partitioning, formatting, hardware config generation, and `nixos-install`. See [INSTALL.md](INSTALL.md) for the manual process.

## Rebuild

```bash
sudo nixos-rebuild switch --flake .#gaia
```

Or use the shell aliases: `rebuild`, `rebuild-test`, `rebuild-boot`.

## Strix Halo / ROCm

- **RADV** for graphics, **AMDVLK** available via `AMD_VULKAN_ICD=AMDVLK`
- **128GB unified memory** — GTT set to 120GB for large LLM models
- **ROCm 7** via [nix-strix-halo](https://github.com/hellas-ai/nix-strix-halo) (gfx1151 pre-built binaries)

## Adding another machine

1. Create `hosts/<name>/default.nix` — pick which modules apply
2. Generate `hosts/<name>/hardware.nix` on the hardware
3. Add `home/hyprland/machines/<name>.conf` for monitors
4. Add a `nixosConfigurations.<name>` entry in `flake.nix`

Everything in `home/` is shared across machines.

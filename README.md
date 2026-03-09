# Gaia — NixOS Configuration

NixOS flake configuration for **Gaia**, a Minisforum MS-S1 MAX desktop (AMD Ryzen AI Max+ 395 / Strix Halo). Full desktop rice built on [HyDE](https://github.com/HyDE-Project/HyDE) (Hyprland Dynamic Environment), migrated from a script-based install to declarative Nix.

## Fresh Install

Boot a NixOS minimal ISO, connect to network, then:

```bash
nix-shell -p git git-lfs
git lfs install
git clone https://github.com/sigilmakes/dotfiles.git
cd dotfiles
bash install.sh
```

The script walks you through disk selection, partitioning (ext4 or btrfs), formatting, hardware config generation, and `nixos-install`. See [INSTALL.md](INSTALL.md) for the full manual process and troubleshooting.

## Rebuilding

```bash
# Build and activate (adds to boot menu + switches immediately)
sudo nixos-rebuild switch --flake .#gaia

# Test without adding to boot menu (rollback on reboot)
sudo nixos-rebuild test --flake .#gaia
```

Shell aliases in `home/shell/bash.nix`:

| Alias | Command |
|-------|---------|
| `rebuild` | `sudo nixos-rebuild switch --flake ~/Projects/gaia-nix#gaia` |
| `rebuild-test` | `sudo nixos-rebuild test --flake ~/Projects/gaia-nix#gaia` |
| `rebuild-boot` | `sudo nixos-rebuild boot --flake ~/Projects/gaia-nix#gaia` |

## Directory Structure

```
gaia-nix/
├── flake.nix                  # Entry point — nixpkgs, home-manager, xivlauncher-rb,
│                               #   nix-strix-halo inputs + "gaia" system config
├── install.sh                 # Interactive installer for fresh NixOS installs
│
├── hosts/gaia/
│   ├── default.nix            # Host config — imports all system modules
│   └── hardware.nix           # ⚠️ PLACEHOLDER — generate with nixos-generate-config
│
├── modules/                   # System-level NixOS modules (run as root)
│   ├── core/
│   │   ├── boot.nix           # systemd-boot, latest kernel, AMD microcode, zram
│   │   ├── locale.nix         # en_GB, Europe/London, UK keyboard
│   │   ├── networking.nix     # NetworkManager, firewalld
│   │   └── users.nix          # User accounts and groups
│   ├── desktop/
│   │   ├── audio.nix          # PipeWire audio stack
│   │   ├── fonts.nix          # Nerd Fonts, CJK, emoji
│   │   ├── greetd.nix         # Login manager (tuigreet)
│   │   └── hyprland.nix       # Hyprland system-level + Wayland env vars
│   ├── hardware/
│   │   ├── bluetooth.nix      # Bluetooth + Blueman applet
│   │   ├── gpu-amd.nix        # RADV + AMDVLK, Mesa, VA-API, GTT 120GB for LLMs
│   │   └── rocm.nix           # ROCm overlay via nix-strix-halo (gfx1151)
│   ├── gaming/
│   │   ├── steam.nix          # Steam + Proton + MangoHud + GameMode
│   │   ├── launchers.nix      # PrismLauncher, Lutris, emulators (RPCS3, PCSX2, OpenMW)
│   │   ├── xivlauncher.nix    # XIVLauncher-RB (rankynbass fork)
│   │   ├── dualsense.nix      # DualSense controller udev + dualsensectl
│   │   └── sunshine.nix       # Sunshine remote play server
│   └── services/
│       ├── docker.nix         # Rootless Docker
│       ├── printing.nix       # CUPS + gutenprint
│       └── ssh.nix            # SSH daemon (key-only auth)
│
├── home/                      # User-level config via Home Manager
│   ├── default.nix            # Entry point — curried function with hostname/username/git identity
│   ├── mutable.nix            # Mutable file support (wallbash needs writable configs)
│   ├── shell/
│   │   ├── bash.nix           # Bash config, aliases, shell integrations
│   │   └── git.nix            # Git + GitHub CLI config
│   ├── apps/
│   │   ├── firefox/           # Firefox + userChrome.css (Sidebery tree-style tabs)
│   │   ├── kitty.nix          # Terminal emulator
│   │   ├── micro.nix          # Text editor + plugins (fzf, filemanager, aspell)
│   │   ├── waybar.nix         # Status bar + clipboard tools
│   │   ├── swaync.nix         # Notification center (SwayNC)
│   │   ├── rofi.nix           # App launcher / menu system
│   │   ├── swaylock.nix       # Screen locker
│   │   ├── wlogout.nix        # Logout / power menu
│   │   ├── screenshots.nix    # Screenshot tools (grim + slurp + swappy)
│   │   ├── vesktop.nix        # Discord (Vencord)
│   │   ├── easyeffects.nix    # Audio effects / EQ
│   │   ├── keyring.nix        # gnome-keyring + seahorse
│   │   ├── mangohud.nix       # Gaming performance overlay
│   │   ├── scopebuddy.nix     # Crosshair overlay for games
│   │   ├── sunshine.nix       # Sunshine user config
│   │   ├── ai.nix             # Node.js, Python, uv (for AI tools)
│   │   ├── cli-tools.nix      # bat, ripgrep, fd, pandoc, texlive, etc.
│   │   ├── utilities.nix      # Obsidian, krita, libreoffice, gparted, etc.
│   │   ├── networking.nix     # ProtonVPN, qBittorrent
│   │   ├── media.nix          # OBS Studio, helvum, guvcview
│   │   └── ...
│   ├── scripts/
│   │   ├── default.nix        # HyDE scripts packaged as a Nix derivation
│   │   └── src/               # 50+ shell scripts (volume, brightness, theming, etc.)
│   ├── hyprland/
│   │   ├── default.nix        # Session config (env vars, autostart, exec-once)
│   │   ├── keybindings.nix    # All keyboard/mouse bindings
│   │   ├── windowrules.nix    # Per-app window rules and layouts
│   │   ├── animations.nix     # Bezier curves and animation defs
│   │   ├── input.nix          # Keyboard, mouse, touchpad
│   │   ├── hypridle.nix       # Idle/lock daemon
│   │   └── machines/          # Per-machine config (monitors, $term, exec-once)
│   │       ├── gaia.conf
│   │       └── template.conf
│   └── theming/
│       ├── gtk.nix            # GTK 2/3/4 theme settings
│       ├── qt.nix             # Qt5/Qt6 + Kvantum theming
│       ├── cursor.nix         # Cursor theme
│       ├── wallbash.nix       # Wallbash color engine + swww wallpaper daemon
│       └── themes.nix         # 16 HyDE themes + wallpapers
│
└── themes/                    # Theme data (wallpapers tracked with Git LFS)
    ├── Abyssal-Wave/
    ├── crimson/
    ├── decay green/
    ├── Memento Mori/
    ├── monokai/
    ├── rose pine/
    ├── Timeless Dream/
    └── ... (16 total)
```

## Adding Another Machine

The config is multi-machine ready. Adding a second host (e.g. a laptop) needs:

1. `hosts/<name>/default.nix` — import the modules that apply (skip `rocm.nix` on Intel, etc.)
2. `hosts/<name>/hardware.nix` — generated on the hardware with `nixos-generate-config`
3. `home/hyprland/machines/<name>.conf` — monitors, `$term`/`$browser` vars, machine-specific exec-once
4. New `nixosConfigurations.<name>` entry in `flake.nix` with `hostname = "<name>"`

Everything in `home/` is shared — the entire rice, scripts, theming, and apps deploy identically across machines. Only hardware, GPU, and monitor config differ per host.

## How the Theming System Works

HyDE's theming is **wallpaper-driven** — colors for the entire desktop are generated from the current wallpaper:

1. **Pick a theme or wallpaper** (keybind, rofi menu, or `themeswitch.sh`)
2. **swww** sets the wallpaper (with transition animation)
3. **imagemagick** extracts dominant colors
4. **wallbash** reads `.dcol` templates and fills in the extracted colors
5. Generated configs overwrite theme files for GTK, Qt, Hyprland, kitty, waybar, rofi, etc.

### Mutable files

Home Manager normally creates read-only symlinks. Wallbash needs to overwrite theme files at runtime. The `mutable.nix` module adds `mutable = true` — mutable files get **copied** (with write perms) instead of symlinked.

## Key Bindings

All bindings use **Super** as the main modifier. Defined in `home/hyprland/keybindings.nix`.

| Keybind | Action |
|---------|--------|
| `Super + Return` | Terminal (kitty) |
| `Super + E` | File manager |
| `Super + F` | Web browser |
| `Super + A` | App launcher (rofi) |
| `Super + Tab` | Window switcher |
| `Super + V` | Clipboard history |
| `Super + L` | Lock screen |
| `Super + Space` | Keyboard layout switch |
| `Super + /` | Notification panel toggle |
| `Super + Shift + Q` | Close window |
| `Super + 1-9,0` | Switch workspace |
| `Super + Alt + W` | Next wallpaper |
| `Super + Shift + R` | Theme picker |
| Volume icon click | SwayNC panel |
| Volume icon right-click | pavucontrol |

## Strix Halo / ROCm

Gaia runs an AMD Ryzen AI Max+ 395 with Radeon 8060S (RDNA 3.5, gfx1151, 40 CU, 128GB shared LPDDR5X-8000).

- **Both RADV and AMDVLK** installed — AMDVLK default (faster for LLM pp), switch per-app with `AMD_VULKAN_ICD=RADV`
- **GTT 120GB** for large LLM models (`options ttm pages_limit=31457280`)
- **ROCm via [nix-strix-halo](https://github.com/hellas-ai/nix-strix-halo)** — pre-built TheRock ROCm 7 nightlies for gfx1151
- **llama.cpp with rocWMMA**: `ROCBLAS_USE_HIPBLASLT=1 llama-cpp-gfx1151-rocwmma --mmap 0 --ngl 99 -m model.gguf`

## Known Issues

- **`hardware.nix` is a placeholder** — needs `nixos-generate-config` on gaia
- **`gaia.conf` monitors are auto-detect** — need real output names after first boot
- **`lib.fakeHash` in `scopebuddy.nix`** — first build will fail with hash mismatch; paste the real hash from the error and rebuild
- **Theme wallpapers are Git LFS** (~211MB) — run `git lfs pull` if you see pointer files

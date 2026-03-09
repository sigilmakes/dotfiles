# Installing NixOS on Gaia

Step-by-step guide to get Gaia running from a fresh NixOS USB.

## Quick Install (scripted)

```bash
# Boot NixOS ISO, connect to network, then:
nix-shell -p git git-lfs
git lfs install
git clone https://github.com/sigilmakes/dotfiles.git
cd dotfiles
sudo bash install.sh
```

The script handles partitioning, formatting, hardware config generation, and
`nixos-install`. It's interactive and confirms before anything destructive.

If you prefer doing it manually, follow the steps below.

---

## Manual Install

## Prerequisites

- NixOS minimal ISO on a USB stick ([download](https://nixos.org/download#nixos-iso))
  - Use the **unstable** ISO for best Strix Halo support
- Gaia connected to Ethernet (easier) or know your WiFi credentials
- A keyboard and monitor plugged in

## 1. Boot the Installer

1. Plug the USB into Gaia, power on, mash **F7** (or **Del**) for boot menu
2. Select the USB drive (UEFI mode)
3. You'll land at a root TTY

### Connect to WiFi (if no Ethernet)

```bash
# Interactive WiFi setup
nmtui
# Or command line:
nmcli device wifi connect "YourSSID" password "YourPassword"
```

Verify connectivity:
```bash
ping -c 3 nixos.org
```

## 2. Partition the Disk

Find your NVMe drive:
```bash
lsblk
```

You should see something like `nvme0n1` (the main SSD). Adjust the device name below if different.

### Option A: Simple layout (recommended)

```bash
# Wipe and create GPT partition table
parted /dev/nvme0n1 -- mklabel gpt

# EFI System Partition (512MB)
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on

# Root partition (rest of disk)
parted /dev/nvme0n1 -- mkpart root ext4 512MiB 100%
```

### Format

```bash
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2
```

### Option B: Btrfs with subvolumes (if you want snapshots)

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart root btrfs 512MiB 100%

mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/nvme0n1p2

# Create subvolumes
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt
```

## 3. Mount Filesystems

### For ext4 (Option A):
```bash
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

### For btrfs (Option B):
```bash
mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,nix}
mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p2 /mnt/nix
```

## 4. Generate Hardware Config

```bash
nixos-generate-config --root /mnt
```

This creates `/mnt/etc/nixos/hardware-configuration.nix` with your actual disk UUIDs, filesystem mounts, and detected kernel modules. **We need this file.**

Save it somewhere accessible:
```bash
cat /mnt/etc/nixos/hardware-configuration.nix
```

Keep this terminal open — you'll copy this content in step 6.

## 5. Clone the Config

```bash
# Install git + LFS in the installer environment
nix-shell -p git git-lfs

# Clone the repo
git lfs install
git clone https://github.com/sigilmakes/dotfiles.git /mnt/home/sigil/Projects/Personal/gaia-nix
cd /mnt/home/sigil/Projects/Personal/gaia-nix

# Verify LFS files are pulled (assets should be ~117MB, not pointer files)
du -sh assets/
```

## 6. Replace hardware.nix

Copy the generated hardware config into the repo:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/gaia/hardware.nix
```

**Review it** — make sure it has:
- `fileSystems."/"` with the correct UUID/label
- `fileSystems."/boot"` with the EFI partition
- `swapDevices` (if you created swap, or empty `[]` if not)
- `boot.initrd.availableKernelModules` (auto-detected)

Our `boot.nix` already sets the kernel and AMD microcode, so you can remove
those from the generated file if they conflict. The key things we need from
the generated config are **`fileSystems`**, **`swapDevices`**, and any
hardware-specific **`boot.initrd`** modules.

## 7. Install

```bash
cd /mnt/home/sigil/Projects/Personal/gaia-nix

# Install NixOS using our flake
sudo nixos-install --flake .#gaia --no-root-passwd
```

This will:
- Build the entire system (takes a while on first run — downloading everything)
- Install it to `/mnt`
- Set up the bootloader

**Set your user password** when prompted, or after reboot:
```bash
# If installer doesn't prompt, set it after chroot:
nixos-enter --root /mnt
passwd sigil
exit
```

## 8. Reboot

```bash
umount -R /mnt
reboot
```

Remove the USB stick. Gaia should boot into systemd-boot → greetd → tuigreet.

## 9. First Login

1. tuigreet shows the login screen
2. Log in as `sigil`
3. Hyprland starts automatically
4. First theme switch will populate all wallbash colors

### Fix ScopeBuddy hash (first build only)

The first build will fail with a hash mismatch for ScopeBuddy (not in nixpkgs,
built from source). Nix needs the real hash but we can't know it ahead of time.

1. The build error will print something like:
   ```
   hash mismatch in fixed-output derivation ...
     got: sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=
   ```
2. Copy the `sha256-XXX...` hash
3. Paste it into `home/apps/scopebuddy.nix` line ~42, replacing `lib.fakeHash`
4. Rebuild

### Verify the basics:
- **Super+Enter** → kitty terminal
- **Super+Shift+R** → theme selector (rofi)
- **Super+D** → app launcher
- **Super+N** → night mode toggle
- Waybar should be visible at the bottom with taskbar in center
- Notifications should work (`notify-send "hello"`)
- **Click volume icon** → SwayNC panel with volume slider
- **Right-click volume icon** → pavucontrol

## 10. Post-Install Setup

### Commit hardware.nix back to the repo

```bash
cd ~/Projects/Personal/gaia-nix
git add hosts/gaia/hardware.nix
git commit -m "Add real hardware config from Gaia"
git push
```

### Install AI tools

```bash
# Pi coding agent (Hades)
npm install -g @mariozechner/pi-coding-agent

# nanobot personal assistant
pip install nanobot-ai
# or with uv (faster):
uv tool install nanobot-ai

# Set up nanobot
nanobot onboard
# Then edit ~/.nanobot/config.json with your API keys
```

### Set up SSH keys

```bash
# Generate a new key for Gaia (or copy existing)
ssh-keygen -t ed25519 -C "willow@gaia"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# → paste into https://github.com/settings/keys

# Switch repo remote to SSH
cd ~/Projects/Personal/gaia-nix
git remote set-url origin git@github.com:sigilmakes/dotfiles.git
```

### Verify pkill/killall on wrapped binaries

```bash
# Confirm these processes have the expected names
ps aux | grep -E "waybar|swaync|kitty" | grep -v grep
# Should show .waybar-wrapped, .kitty-wrapped, swaync

# Also verify rofi and wlogout are NOT wrapped (pkill -x should work)
which rofi    # should be a direct binary, not a wrapper
which wlogout
```

### Trigger first theme switch

```bash
# This populates all wallbash colors across the desktop
themeswitch.sh
```

### Verify ROCm + Vulkan

```bash
# Vulkan — should show both RADV and AMDVLK drivers
vulkaninfo --summary

# Force RADV for a specific app (AMDVLK is default when both installed)
AMD_VULKAN_ICD=RADV vulkaninfo --summary

# VA-API hardware video decode
vainfo

# GTT memory limit (should show ~120GB)
cat /sys/class/drm/card*/device/mem_info_gtt_total

# ROCm llama.cpp (quick smoke test)
echo "If you have a GGUF model:" 
echo "ROCBLAS_USE_HIPBLASLT=1 llama-cpp-gfx1151-rocwmma --mmap 0 --ngl 99 -m model.gguf"
```

## Troubleshooting

### Build fails with "path does not exist"
- Check that `git lfs pull` was run — asset tarballs must be real files, not LFS pointers
- `du -sh assets/` should show ~117MB

### No WiFi after reboot
- NetworkManager should auto-connect. If not: `nmtui` from a TTY
- Check `journalctl -u NetworkManager` for errors

### greetd doesn't start / black screen
- Switch to TTY2: **Ctrl+Alt+F2**
- Check logs: `journalctl -u greetd`
- Rebuild: `sudo nixos-rebuild switch --flake ~/Projects/Personal/gaia-nix#gaia`

### Hyprland crashes on login
- Check `~/.local/share/hyprland/hyprland.log` (or `hyprland.log.prev`)
- Common cause: GPU driver issues — check `journalctl -b | grep -i amdgpu`

### Theme switching doesn't update colors
- Run `swwwallbash.sh` manually and check for errors
- Verify `~/.themes/Wallbash-Gtk/gtk-3.0/` exists and is writable

### "command not found" for HyDE scripts
- Check that hyde-scripts is in PATH: `which volumecontrol.sh`
- Rebuild if needed: `sudo nixos-rebuild switch --flake ~/Projects/Personal/gaia-nix#gaia`

## Updating

After first install, updates are:

```bash
cd ~/Projects/Personal/gaia-nix

# Update nixpkgs + home-manager
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#gaia

# Or use the keybind: Super+Shift+U (runs systemupdate.sh)
```

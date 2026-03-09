#!/usr/bin/env bash
set -euo pipefail

# Gaia NixOS installer
#
# Run this from the NixOS minimal ISO after cloning the repo:
#
#   1. Boot NixOS ISO, connect to network (nmtui or Ethernet)
#   2. nix-shell -p git git-lfs
#   3. git lfs install && git clone https://github.com/sigilmakes/dotfiles.git
#   4. cd dotfiles && bash install.sh
#
# This script will:
#   - Help you select and partition a disk
#   - Format and mount filesystems
#   - Generate hardware-configuration.nix
#   - Run nixos-install with the flake
#
# It's interactive and asks for confirmation before destructive operations.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
MOUNT_POINT="/mnt"

info()  { echo -e "${CYAN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }

confirm() {
    read -rp "$(echo -e "${YELLOW}[?]${NC} $1 [y/N] ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ─── Preflight checks ───────────────────────────────────────────────

info "Gaia NixOS Installer"
echo ""

# Must be root
[[ $EUID -eq 0 ]] || error "Run as root (sudo bash install.sh)"

# Check we're in the repo
[[ -f "$REPO_DIR/flake.nix" ]] || error "Run this from the gaia-nix repo root"

# Check git-lfs files are real (not pointer files)
lfs_file=$(find "$REPO_DIR" -name "*.png" -path "*/wallpapers/*" -print -quit)
if [[ -n "$lfs_file" ]]; then
    if head -1 "$lfs_file" | grep -q "version https://git-lfs.github.com"; then
        error "LFS files are pointers! Run: git lfs pull"
    fi
    ok "Git LFS files look good"
else
    warn "No wallpaper files found — LFS might not have pulled"
fi

# Check network
if ping -c 1 -W 3 nixos.org &>/dev/null; then
    ok "Network is up"
else
    error "No network. Connect with: nmtui"
fi

# ─── Disk selection ──────────────────────────────────────────────────

echo ""
info "Available disks:"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
echo ""

read -rp "$(echo -e "${YELLOW}[?]${NC} Enter disk to install on (e.g. nvme0n1): ")" DISK
DISK="/dev/$DISK"

[[ -b "$DISK" ]] || error "$DISK is not a valid block device"

echo ""
warn "This will ERASE ALL DATA on $DISK"
lsblk "$DISK"
echo ""
confirm "Are you absolutely sure?" || exit 1

# ─── Partition scheme ────────────────────────────────────────────────

echo ""
info "Partition scheme:"
echo "  1) ext4  — simple, reliable (recommended)"
echo "  2) btrfs — snapshots, compression, subvolumes"
echo ""
read -rp "$(echo -e "${YELLOW}[?]${NC} Choice [1/2]: ")" SCHEME

case "$SCHEME" in
    2) FS="btrfs" ;;
    *) FS="ext4" ;;
esac

ok "Using $FS"

# ─── Partitioning ───────────────────────────────────────────────────

info "Partitioning $DISK..."

parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart root "$FS" 512MiB 100%

# Figure out partition names (nvme uses p1/p2, sata uses 1/2)
if [[ "$DISK" == *nvme* ]] || [[ "$DISK" == *mmcblk* ]]; then
    PART_BOOT="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_ROOT="${DISK}2"
fi

ok "Partitioned: $PART_BOOT (EFI) + $PART_ROOT (root)"

# ─── Formatting ─────────────────────────────────────────────────────

info "Formatting..."

mkfs.fat -F 32 -n BOOT "$PART_BOOT"

if [[ "$FS" == "btrfs" ]]; then
    mkfs.btrfs -f -L nixos "$PART_ROOT"

    # Create subvolumes
    mount "$PART_ROOT" "$MOUNT_POINT"
    btrfs subvolume create "$MOUNT_POINT/@"
    btrfs subvolume create "$MOUNT_POINT/@home"
    btrfs subvolume create "$MOUNT_POINT/@nix"
    umount "$MOUNT_POINT"
else
    mkfs.ext4 -F -L nixos "$PART_ROOT"
fi

ok "Formatted"

# ─── Mounting ────────────────────────────────────────────────────────

info "Mounting filesystems..."

if [[ "$FS" == "btrfs" ]]; then
    mount -o subvol=@,compress=zstd,noatime "$PART_ROOT" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT"/{boot,home,nix}
    mount "$PART_BOOT" "$MOUNT_POINT/boot"
    mount -o subvol=@home,compress=zstd,noatime "$PART_ROOT" "$MOUNT_POINT/home"
    mount -o subvol=@nix,compress=zstd,noatime "$PART_ROOT" "$MOUNT_POINT/nix"
else
    mount "$PART_ROOT" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT/boot"
    mount "$PART_BOOT" "$MOUNT_POINT/boot"
fi

ok "Mounted at $MOUNT_POINT"

# ─── Generate hardware config ───────────────────────────────────────

info "Generating hardware configuration..."

nixos-generate-config --root "$MOUNT_POINT"

# Copy the generated hardware config into our repo
cp "$MOUNT_POINT/etc/nixos/hardware-configuration.nix" "$REPO_DIR/hosts/gaia/hardware.nix"

ok "Hardware config saved to hosts/gaia/hardware.nix"

# ─── Place the repo ─────────────────────────────────────────────────

info "Copying config to target system..."

DEST="$MOUNT_POINT/home/sigil/Projects/gaia-nix"
mkdir -p "$(dirname "$DEST")"
cp -a "$REPO_DIR" "$DEST"

ok "Config placed at $DEST"

# ─── Install ─────────────────────────────────────────────────────────

echo ""
info "Ready to install NixOS"
warn "This will download and build everything — could take 20-60 minutes"
echo ""
confirm "Proceed with nixos-install?" || { warn "Aborted. Filesystems still mounted at $MOUNT_POINT"; exit 1; }

info "Installing... (grab a coffee)"

nixos-install --flake "$DEST#gaia" --no-root-passwd

echo ""
ok "NixOS installed!"

# ─── Set password ────────────────────────────────────────────────────

echo ""
info "Set password for sigil:"
nixos-enter --root "$MOUNT_POINT" -- passwd sigil

# ─── Done ────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
info "Next steps:"
echo "  1. umount -R /mnt"
echo "  2. reboot  (remove USB stick)"
echo "  3. Log in as sigil"
echo "  4. Run: themeswitch.sh  (populates wallbash colors)"
echo ""
warn "First rebuild will fail on ScopeBuddy hash — see INSTALL.md §9"
echo ""

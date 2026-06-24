#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root: sudo ./nik.sh"
  exit 1
fi

# 1. Added --script here so parted doesn't prompt
parted --script /dev/sda -- mklabel gpt
parted --script /dev/sda -- mkpart root ext4 512MB 100%
parted --script /dev/sda -- mkpart ESP fat32 1MB 512MB
parted --script /dev/sda -- set 2 esp on

# 2. Added -F and -I here so formatting doesn't prompt
mkfs.ext4 -F -L nixos /dev/sda1
mkfs.fat -I -F 32 -n boot /dev/sda2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

nixos-generate-config --root /mnt
cp 1337.nix /mnt/etc/nixos/configuration.nix

# 3. Added --no-root-password so it finishes completely unattended
nixos-install --no-root-password

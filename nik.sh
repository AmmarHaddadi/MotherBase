#!/usr/bin/env bash
set -e # Exit immediately if a command exits with a non-zero status

# Ensure the script is being run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root: sudo ./nik.sh"
  exit 1
fi

# Partitioning
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 2 esp on

# Formatting
mkfs.ext4 -L nixos /dev/sda1
mkfs.fat -F 32 -n boot /dev/sda2

# Mounting
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

# Generate hardware config & copy your custom configuration
nixos-generate-config --root /mnt
cp 1337.nix /mnt/etc/nixos/configuration.nix

# Install without prompting for a root password
nixos-install --no-root-password

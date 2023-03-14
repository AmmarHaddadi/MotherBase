#!/bin/bash
name=""
password=""
hostname=""
# makes a partition 1 for /boot, and 2 for the rest
(echo o; echo n; echo p; echo 1; echo ""; echo +300M; echo n; echo p; echo 2; echo ""; echo ""; echo a; echo 1;echo p; echo w) | fdisk /dev/sda

# for VMs, sda should be replaced with vda, in vim do :%s/sda/vda/g
mkfs.ext4 -L ROOT /dev/sda2 
mkfs.vfat -F32 /dev/sda1
dosfslabel /dev/sda1 ESP

# Mounting partitions
mount /dev/disk/by-label/ROOT /mnt
mkdir -pv /mnt/boot/efi
mount /dev/disk/by-label/ESP /mnt/boot/efi

#time
ntpd -qg
rc-service ntpd start
rc-update add ntpd default

#necessery stuff
basestrap /mnt base base-devel linux linux-firmware openrc elogind-openrc vim
fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt

# date time tweaks
ln -sf /usr/share/zoneinfo/Africa/Africa /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8 \nar_MA.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_TIME=en_US.UTF-8" > /etc/locale.conf

#pacamn tweaks
pacman-key --init
# pacman-key --populate archlinux
pacman-key --refresh-keys
pacman -S sed
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/^Color/a ParallelDownloads = 8' /etc/pacman.conf

#install and configure boot loader
pacman -S --needed grub efibootmgr
grub-install --recheck /dev/sda --target=x86_64-efi --bootloader-id=grub_uefi 
grub-mkconfig -o /boot/grub/grub.cfg #for UEFI system

#users and passwords
echo "root:$password" | chpasswd #root pass
useradd -m "$name"
echo "$name:$password" | chpasswd
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
usermod -aG wheel,input,video,audio,sys,network,power "$name"

# network config
echo "$hostname" > /etc/hostname
echo "
# Standard host addresses
127.0.0.1  localhost
::1        localhost ip6-localhost ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters

# This host address
127.0.1.1  "$name"
" > /etc/hosts
echo "hostname=$hostname" > /etc/conf.d/hostname
pacman -S dhcpcd networkmanager networkmanager-openrc
rc-update add networkmanager

# finishing
exit
umount -R /mnt
reboot
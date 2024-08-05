#!/bin/bash

disk=/dev/sda

short_usage()
{
cat <<HEREDOC
usage: ${0##*/} [--help|-h|-?] [--disk|-d DISK] ROOT_PASSWORD
HEREDOC
}

usage()
{
short_usage
cat <<HEREDOC

This script is not meant to be run directly as of right now.

Before trusting these as instructions, verify they are up to date by comparing against the arch wiki.
https://wiki.archlinux.org/title/Installation_guide

There is also always the easy way out: using archinstall.
HEREDOC
}

usage
exit 0

while [ ${#} -ne 1 ]
do
  current_opt="${1}"
  case "${current_opt}" in
    --disk|-d)
      shift

      if [ ${#} -ne 0 ]
      then
        disk="${1}"
        shift
      else
        echo "ERROR: missing disk after ${current_opt}"
        exit 1
      fi
      ;;

    --help|-h|-?)
      usage
      exit 0
      ;;

    -*)
      echo "ERROR: unrecognized option \"${current_opt}\""
      short_usage
      exit 1
      ;;

    *)
      break
      ;;
  esac
done

if [ ${#} -eq 1 ]
then
  root_password="${1}"
else
  echo "ERROR: missing root password"
  short_usage
  exit 1
fi

boot_part="${disk}"1
swap_part="${disk}"2
rest_part="${disk}"3

timedatectl set-ntp true

# supposedly sfdisk is best for scripting, but fdisk will also work (cfdisk is a user friendly tui)
cfdisk "${disk}"
# 512M for bootable partition (grub, initramfs, other kernel shit possibly)
# 4G for swap
# rest for everything else (root partition)

mkfs.fat -F 32 "${boot_part}"
mkswap "${swap_part}"
mkfs.ext4 "${rest_part}"

mount "${rest_part}" /mnt
mkdir /mnt/boot
mount "${boot_part}" /mnt/boot
swapon "${swap_part}"

pacstrap -K /mnt base base-devel linux linux-firmware man-db man-pages texinfo vim grub networkmanager git

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<ENDCMDS
systemctl enable NetworkManager
grub-install "${disk}"
grub-mkconfig -o /boot/grub/grub.cfg
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
sed -ri 's/# (en_US.UTF-8 UTF-8)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "hostname" > /etc/hostname
passwd -s <<ENDPASS
${root_password}
ENDPASS
ENDCMDS

umount -R /mnt || { echo "ERROR: umount failed. Manual inspection advised"; exit 1; }
reboot

# [EOF]

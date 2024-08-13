#!/bin/bash

short_usage()
{
cat <<HEREDOC
usage: ${0##*/} [--help|-h|-?]
HEREDOC
}

usage()
{
short_usage
cat <<HEREDOC

EXAMPLE
    ${0##*/} /dev/sda

Before trusting this script, verify the steps are up to date by comparing against the arch wiki.
https://wiki.archlinux.org/title/Installation_guide

There is also always the easy way out: using archinstall.
HEREDOC
}

err_check()
{
if [ $? -ne 0 ]
then
  echo "failed"
  exit 1
else
  echo "done"
fi
}

while [ ${#} -ne 1 ]
do
  curr_opt="${1}"
  case "${curr_opt}" in
    --help|-h|-?)
      usage
      exit 0
      ;;

    -*)
      echo "ERROR: unrecognized option \"${curr_opt}\""
      short_usage
      exit 1
      ;;

    *)
      break
      ;;
  esac
done

disks="$(lsblk -o PATH,TYPE | grep disk | cut -d " " -f 1)"
lsblk ${disks}

i=1
echo
for disk in ${disks}
do
  echo -n "(${i}) ${disk}, "
  choice[${i}]="${disk}"
  i=$((i + 1))
done
echo -e "\b\b "

read -p "Choose a disk: " -n 1
echo

disk="${choice[${REPLY}]}"
if [ "${disk}" == "" ]
then
  echo "ERROR: Invalid disk choice"
  exit 1
fi

while [ "${root_password}" == "" ]
do
  read -s -p "Set password for root user: " root_password
  echo

  if [ "${root_password}" == "" ]
  then
    echo "WARNING: Root password can't be empty"
  fi
done
read -s -p "Enter it one more time: " root_password2
echo

if [ ! "${root_password}" == "${root_password2}" ]
then
  echo "ERROR: Passwords don't match"
  exit 1
fi

while [ "${password}" == "" ]
do
  read -s -p "Set password for user: " password
  echo

  if [ "${password}" == "" ]
  then
    echo "WARNING: Password can't be empty"
  fi
done
read -s -p "One more time: " password2
echo

if [ ! "${password}" == "${password2}" ]
then
  echo "ERROR: Passwords don't match"
  exit 1
fi

boot_part="${disk}"1
swap_part="${disk}"2
rest_part="${disk}"3

timedatectl set-ntp true

# check if disk has partitions or partiton table (and needs wiped)
if [ $(lsblk -no KNAME,FSTYPE "${disk}" | wc -w) -ne 1 ]
then
  echo "WARNING: ${disk} is already formatted or has partitions"
  read -p "Wipe disk and continue (y/N)? " -n 1
  echo

  if [[ $REPLY =~ ^[yY]$ ]]
  then
    echo "Wiping ${disk}..."
    dd if=/dev/urandom of="${disk}" bs=1M status=progress
    echo -ne "\033[6A\033[18Cdone\n\033[J"
  else
    exit 0
  fi
fi

# 512M for bootable partition (grub, initramfs, etc.)
# 4G for swap
# rest for everything else (root partition)
echo -n "Creating partitions on ${disk}..."
fdisk "${disk}" <<ENDCMDS > /dev/null
o
n
p
1

+512M
n
p
2

+4G
n
p
3


w
ENDCMDS
err_check

echo "Building filesystems..."
echo -n "  Creating fat32 on ${boot_part}..."
mkfs.fat -F 32 "${boot_part}" > /dev/null 2>&1; err_check
echo -n "  Creating swap on ${swap_part}..."
mkswap "${swap_part}" > /dev/null 2>&1; err_check
echo -n "  Creating ext4 on ${rest_part}..."
mkfs.ext4 "${rest_part}" > /dev/null 2>&1; err_check
echo -ne "\033[s\033[4A\033[23Cdone\033[u"

echo "Mounting partitions..."
echo -n "  Mounting root partition ${rest_part}..."
mount "${rest_part}" /mnt; err_check
echo -n "  Mounting boot partition ${boot_part}..."
mkdir /mnt/boot
mount "${boot_part}" /mnt/boot; err_check
echo -n "  Turning swap (${swap_part}) on..."
swapon "${swap_part}"; err_check
echo -ne "\033[s\033[4A\033[22Cdone\033[u"

echo "Installing required packages..."
pacstrap -K /mnt base base-devel linux linux-firmware man-db man-pages texinfo vim grub networkmanager git

echo -n "Generating /etc/fstab..."
genfstab -U /mnt >> /mnt/etc/fstab; err_check

arch-chroot /mnt /bin/bash <<ENDCMDS || exit $?
err_check()
{
if [ \$? -ne 0 ]
then
  echo "failed"
  exit 1
else
  echo "done"
fi
}

echo -n "Enabling network manager..."
systemctl enable NetworkManager > /dev/null 2>&1; err_check

echo -n "Installing grub..."
grub-install "${disk}" > /dev/null 2>&1; err_check
echo -n "Making grub config..."
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1; err_check

echo -n "Setting time zone..."
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime; err_check
echo -n "Setting hardware clock..."
hwclock --systohc; err_check

echo -n "Choosing locale..."
sed -ri 's/#(en_US.UTF-8 UTF-8)/\1/' /etc/locale.gen; err_check
echo -n "Generating locale..."
locale-gen > /dev/null; err_check
echo -n "Generating /etc/locale.conf..."
echo "LANG=en_US.UTF-8" > /etc/locale.conf; err_check
echo -n "Setting hostname..."
echo "hostname" > /etc/hostname; err_check

echo -n "Setting root password..."
passwd -s <<ENDPASS
${root_password}
ENDPASS
err_check

echo -n "Adding user..."
useradd -mG wheel user; err_check
echo -n "Setting user password..."
passwd -s user <<ENDPASS
${password}
ENDPASS
err_check

echo -n "Backing up /etc/sudoers..."
cp /etc/sudoers /etc/sudoers.bak; err_check
echo -n "Setting wheel sudo permissions..."
sed -ri 's/# (%wheel ALL=\(ALL:ALL\) ALL)/\1/' /etc/sudoers; err_check
ENDCMDS


echo -n "Unmounting partitions..."
umount -R /mnt; err_check

echo
for i in {15..0}
do
  echo -ne "\rRebooting in ${i} seconds "
  sleep 1
done

reboot

# [EOF]

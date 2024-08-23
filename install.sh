#!/bin/bash

#
# cmdline option defaults
#
if [ "${noreboot}" == "" ]
then
  noreboot=N
fi

short_usage()
{
cat <<HEREDOC
usage: ${0##*/} [--help|-h|-?] [--logfile|-l FILE] [--noreboot|-n]
HEREDOC
}

usage()
{
short_usage
cat <<HEREDOC

DESCRIPTION
    Before trusting this script, verify the steps are up to date by comparing against the arch wiki:
    https://wiki.archlinux.org/title/Installation_guide

    With the exception of prompting for passwords and what drive to use, this script automates the arch
    linux install from partitioning to setting up my dot files.

OPTIONS
    -h, -?, --help 
        Display this help message and exit.

    -l, --logfile FILE
        Log script outputs to FILE in addition to the terminal. It's the same as running "${0} --noreboot |& tee FILE".

    -n, --noreboot
        Do not reboot once the install is complete.
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

while [ ${#} -ne 0 ]
do
  curr_opt="${1}"
  case "${curr_opt}" in
    --help|-h|-\?)
      usage
      exit 0
      ;;

    --logfile|-l)
      shift

      if [ ${#} -ne 0 ]
      then
        logfile="${1}"
        shift
      else
        echo "ERROR: missing logfile after ${curr_opt}"
        short_usage
        exit 1
      fi

      logfile="${logfile}" noreboot="${noreboot}" ${0} ${@} |& tee "${logfile}"
      exit 0
      ;;

    --noreboot|-n)
      shift
      noreboot=Y
      ;;

    *)
      echo "ERROR: unrecognized option \"${curr_opt}\""
      short_usage
      exit 1
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

read -p "Name for new user: " user
while [ "${user_password}" == "" ]
do
  read -s -p "Set password for user: " user_password
  echo

  if [ "${user_password}" == "" ]
  then
    echo "WARNING: Password can't be empty"
  fi
done
read -s -p "One more time: " user_password2
echo

if [ ! "${user_password}" == "${user_password2}" ]
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
    echo -n "Unmounting all partitions on ${disk}..."
    umount ${disk}* 2> /dev/null; echo "done"
    echo -n "Turning off swap (if any) on ${disk}..."
    swapoff ${disk}* 2> /dev/null; echo "done"
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

echo -n "Moving images to root home directory..."
mv ~/arch-install/img /mnt/root; err_check
echo -n "Moving configure.sh to root home directory..."
mv ~/arch-install/configure.sh /mnt/root; err_check

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
useradd -mG wheel "${user}"; err_check
echo -n "Setting user password..."
passwd -s "${user}" <<ENDPASS
${user_password}
ENDPASS
err_check

echo -n "Changing ownership of wallpapers..."
chown -R "${user}":"${user}" /root/img; err_check
echo -n "Moving wallpapers to user's home directory..."
mv /root/img /home/"${user}"/wallpapers; err_check

echo -n "Changing ownership of configure.sh..."
chown "${user}":"${user}" /root/configure.sh; err_check
echo -n "Moving configure.sh to user's home directory..."
mv /root/configure.sh /home/"${user}"; err_check

echo -n "Backing up /etc/sudoers..."
cp /etc/sudoers /etc/sudoers.bak; err_check
echo -n "Setting wheel sudo permissions..."
sed -ri 's/# (%wheel ALL=\(ALL:ALL\) ALL)/\1/' /etc/sudoers; err_check
echo -n "Saving /etc/sudoers..."
cp /etc/sudoers /etc/sudoers.real; err_check
echo -n "Swapping /etc/sudoers with backup..."
cp -f /etc/sudoers.bak /etc/sudoers; err_check
echo -n "Setting temp wheel sudo permissions..."
sed -ri 's/# (%wheel ALL=\(ALL:ALL\) NOPASSWD: ALL)/\1/' /etc/sudoers; err_check

echo -n "Enabling 32-bit support..."
sed -rzi 's|#(\[multilib\])\n#(Include = /etc/pacman.d/mirrorlist)|\1\n\2|' /etc/pacman.conf; err_check
pacman -Sy

echo "Installing yay..."
cd /opt || exit \$?
git clone https://aur.archlinux.org/yay-git.git
chown -R "${user}":"${user}" yay-git
cd yay-git || exit \$?

su "${user}" <<ENDUSERCMDS || exit \$?
echo "Running makepkg..."
makepkg -si --noconfirm
ENDUSERCMDS

# install gnome except for:
#   gnome-tour, gvfs-afc, gvfs-dnssd, gvfs-goa, gvfs-onedrive, orca, simple-scan
pacman -S --noconfirm baobab epiphany evince gdm gnome-backgrounds gnome-calculator gnome-calendar \
  gnome-characters gnome-clocks gnome-color-manager gnome-connections gnome-console \
  gnome-contacts gnome-control-center gnome-disk-utility gnome-font-viewer gnome-keyring \
  gnome-logs gnome-maps gnome-menus gnome-music gnome-remote-desktop gnome-session \
  gnome-settings-daemon gnome-shell gnome-shell-extensions gnome-software gnome-system-monitor \
  gnome-text-editor gnome-user-docs gnome-user-share gnome-weather grilo-plugins gvfs gvfs-google \
  gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb gvfs-wsdd loupe malcontent nautilus rygel snapshot sushi \
  tecla totem tracker3-miners xdg-desktop-portal-gnome xdg-user-dirs-gtk yelp

systemctl enable gdm

# from gnome-extra:
# gnome-recipes - literally food recipes
# gnome-sound-recorder - probably just use to see if my mic is working lol
# gnome-tweaks - extra settings
# seahorse - password and key manager
pacman -S --noconfirm gnome-recipes gnome-sound-recorder gnome-tweaks seahorse

# extras
pacman -S --noconfirm foot ttf-jetbrains-mono-nerd libsixel neofetch zoxide fzf thefuck firefox glow \
  bat jq ripgrep fd wl-clipboard poppler ffmpegthumbnailer p7zip imagemagick yazi onefetch tldr

su "${user}" <<ENDUSERCMDS
echo "Installing rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# extras (AUR)
yay -S --noconfirm spotify-player-full-pipe
ENDUSERCMDS

echo -n "Restoring wheel sudo permissions..."
mv -f /etc/sudoers.real /etc/sudoers; err_check

# this is necessary
neofetch
ENDCMDS

if [ ! "${logfile}" == "" ]
then
  echo -n "Moving logfile "${logfile}" to user's home directory..."
  mv "${logfile}" /mnt/home/"${user}"; err_check
  echo -n "Changing logfile owner to ${user}..."
arch-chroot /mnt /bin/bash <<ENDCMDS
chown "${user}":"${user}" /home/"${user}"/"${logfile##*/}" || exit \$?
ENDCMDS
  err_check
fi

echo -n "Unmounting partitions..."
umount -R /mnt; err_check

echo
if [ ${noreboot} == Y ]
then
  echo "Install complete!"
else
  for i in {15..0}
  do
    echo -ne "\rRebooting in ${i} seconds "
    sleep 1
  done

  reboot
fi

# [EOF]

#!/bin/bash

#
# cmdline option defaults
#
redirect_file=/dev/null

short_usage()
{
cat <<HEREDOC
usage: ${0##*/} [--help|-h|-?] [--no-git|-g] [--verbose|-v] password
HEREDOC
}

usage()
{
short_usage
cat <<HEREDOC

DESCRIPTION
    Install programs, setup user, download dotfiles, and configure permissions from fresh Arch install.

ARGUMENTS
    password
        The password to set for the user that is created.

OPTIONS
    --help, -h, -?
        Print this help message and exit.
    --verbose, -v
        Show command outputs.
HEREDOC
}

error_check()
{
ret_val=$?
err_msg="${1}"
if [ $ret_val -ne 0 ]
then
  echo "ERROR:${err_msg}"
  return $ret_val
fi

return $ret_val
}

#
# process cmdline args/options
#
while [ ${#} -gt 1 ]
do
  current_option="${1}"

  case "${current_option}" in
    --help|-h|-?)
      usage
      exit 0
      ;;

    --verbose|-v)
      shift
      redirect_file=/dev/stdin
      ;;

    -*)
      echo "ERROR: unrecognized option \"${current_option}\""
      short_usage
      exit 1
      ;;

    *)
      break
      ;;
  esac
done

if [ ${#} -ne 1 ]
then
    echo "ERROR: expected 1 (non-option) argument, received ${#}"
    short_usage
    exit 1
fi

password="${1}"

echo "Consider running this command by tee'ing to a log file like this:"
echo "${0##*/} |& tee install.log.\$\$"
echo
read -p "Press ENTER to continue: " junk

# create user
useradd -mG wheel user
passwd -s user <<ENDPASS
${password}
ENDPASS

# give wheel sudo perms
cp /etc/sudoers /etc/sudoers.backup  # back up sudoers just in case
sed -ri 's/# (%wheel ALL=\(ALL:ALL\) ALL)/\1/' /etc/sudoers
error_check "Failed to set wheel permissions"

# update
pacman -Syu

# install yay
cd /opt
git clone https://aur.archlinux.org/yay-git.git
chown -R user:user yay-git
cd yay-git

su user <<ENDCMDS
makepkg -si
ENDCMDS

# set up dot-files
su user <<ENDCMDS
cd /home/user
git clone https://github.com/Eric-McKinney/dot-files.git > "${redirect_file}"

ret_val=\$?
if [ \$ret_val -ne 0 ]
then
  echo "WARNING: couldn't clone dot-files"
  echo "Continuing..."
else
  cd dot-files || error_check "Couldn't cd into dot-files repo"

  ret_val=\$?
  if [ \$ret_val -eq 0 ]
  then
    files=".bashrc .bash_aliases .profile .vimrc .gitconfig"
    ln \${files} /home/user
  fi

  cp -r .vim /home/user
fi
ENDCMDS

# enable 32-bit support
# echo "Enabling 32-bit support..."
# sed -ri 's/#(\[multilib\])/\1/' /etc/pacman.conf
# sed -ri 's/#(Include = /etc/pacman.d/mirrorlist)/\1/' /etc/pacman.conf
#  ^ replaces too many of these (I only want the one below [multilib])
pacman -Syu

pacman -S gnome
# exclude gnome-tour, gvfs-afc, gvfs-dnssd, gvfs-goa, gvfs-onedrive, orca, simple-scan
systemctl enable gdm

# from gnome-extra:
# gnome-recipes - literally food recipes
# gnome-sound-recorder - probably just use to see if my mic is working lol
# gnome-tweaks - extra settings
# seahorse - password and key manager
pacman -S gnome-recipes gnome-sound-recorder gnome-tweaks seahorse

pacman -S ttf-jetbrains-mono-nerd libsixel

# this is necessary
pacman -S --noconfirm neofetch > "${redirect_file}" && neofetch

sleep 10
reboot

# [EOF]

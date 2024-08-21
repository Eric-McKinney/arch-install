#!/bin/bash

short_usage()
{
cat <<HEREDOC
usage: ${0##*/} [--help|-h|-?] [--logfile|-l FILE]
HEREDOC
}

usage()
{
short_usage
cat <<HEREDOC

DESCRIPTION
    Creates configuration files for various programs. This script will overwrite your existing dotfiles (.bashrc, .vimrc, .profile, etc.), so be careful.

OPTIONS
    -h, -?, --help
        Display this help message and exit.

    -l, --logfile FILE
        Log script outputs to FILE in addition to the terminal. It's the same as running "${0} |& tee FILE".
HEREDOC
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

      ${0} |& tee "${logfile}"
      exit 0
      ;;

    *)
      echo "ERROR: unrecognized option \"${curr_opt}\""
      short_usage
      exit 1
      ;;
  esac
done

err_check()
{
if [ $? -ne 0 ]
then
  echo "failed"
  exit $?
else
  echo "done"
fi
}

user="$(whoami)"
read -s -p "[sudo] password for ${user}: " sudo_password
echo

echo "Installing powerline shell prompt..."
cd /home/"${user}" || exit $?
git clone --recursive https://github.com/andresgongora/synth-shell-prompt.git
synth-shell-prompt/setup.sh <<HEREDOC
n
HEREDOC

echo "Setting up dotfiles..."
git clone https://github.com/Eric-McKinney/dot-files.git .dot-files
ret_val=$?
if [ $ret_val -ne 0 ]
then
  echo "WARNING: couldn't clone dot-files"
  echo "Continuing..."
else
  cd .dot-files || exit $?

  files=".bashrc .bash_aliases .profile .vimrc .gitconfig"
  ln -f ${files} /home/"${user}"
  mkdir -p /home/"${user}"/.config/foot
  ln -f foot.ini /home/"${user}"/.config/foot/foot.ini
  ln -f synth-shell-prompt.config /home/"${user}"/.config/synth-shell/synth-shell-prompt.config
  cp -r .vim /home/"${user}"
fi

cd /home/"${user}"
git clone https://github.com/junegunn/fzf-git.sh

echo "${sudo_password}" | sudo -S --prompt="" true > /dev/null 2>&1
sudo -i <<ENDSUDOCMDS
err_check()
{
if [ \$? -ne 0 ]
then
  echo "failed"
  exit \$?
else
  echo "done"
fi
}

echo "Configuring grub theme..."
echo -n "  Changing background owner to root..."
chown root:root /home/"${user}"/wallpapers/dell-thunder.jpg; err_check
echo -n "  Changing background..."
mv /home/"${user}"/wallpapers/dell-thunder.jpg /boot/grub/themes
sed -ri 's|#(GRUB_BACKGROUND)=".*"|\1="/boot/grub/themes/dell-thunder.jpg"|' /etc/default/grub
err_check
echo -n "  Changing resolution..."
sed -ri 's/(GRUB_GFXMODE)=.*/\1=640x480/' /etc/default/grub; err_check
echo -n "  Making grub config..."
grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1; err_check
echo -ne "\033[s\033[4A\033[25Cdone\033[u"
ENDSUDOCMDS

# extras (flatpak)
flatpak install -y com.discordapp.Discord com.spotify.Client

# set up firefox background
echo "Creating firefox config..."
echo -n "  Starting firefox in headless mode..."
firefox --headless > /dev/null 2>&1 &
[ $? -eq 0 ] && echo "done"
echo -n "  Waiting for profile directory to be created..."
profile_dir=$(ls -d /home/"${user}"/.mozilla/firefox/*.default-release 2> /dev/null)
while [ ! -d "${profile_dir}" ]
do
  sleep 0.1
  profile_dir=$(ls -d /home/"${user}"/.mozilla/firefox/*.default-release 2> /dev/null)
done
sleep 2  # buffer a little bit to be safe
echo "done"
echo -n "  Closing firefox..."
pkill firefox > /dev/null 2>&1; echo "done"
echo -n "  Creating directories..."
mkdir -p "${profile_dir}"/chrome/img; err_check
echo -n "  Creating hard link for css file..."
ln /home/"${user}"/.dot-files/userContent.css "${profile_dir}"/chrome; err_check
echo -n "  Copying wallpaper..."
cp /home/"${user}"/wallpapers/moonlight_mountain_purple.jpg "${profile_dir}"/chrome/img; err_check
echo -n "  Fixing file ownership..."
chown -R "${user}":"${user}" "${profile_dir}"/chrome; err_check
echo "INFO: for the changes to firefox wallpaper to apply, make the following change in about:config"
echo "      toolkit.legacyUserProfileCustomizations.stylesheets = true"
echo "      then restart firefox"
echo "INFO: changes to about:config should sync with a firefox account, so signing in may be enough"

echo
echo -n "Moving wallpapers/ to ~/Pictures..."
mv ~/wallpapers ~/Pictures; err_check

echo
echo "Configuration complete."

# [EOF]

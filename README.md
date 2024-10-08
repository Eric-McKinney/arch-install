# My Arch Install

## Disclaimer

This install and configure script have only been tested successfully on a VirtualBox VM.
On real hardware the likelihood that this script succeeds is very low unfortunately.

## Partitions

| Partition | Mount Point | Size |
|:---------:|:------------|:----:|
|   Boot    |  /mnt/boot  | 512M |
|   Swap    |   [SWAP]    |  4G  |
|   Root    |    /mnt     | Rest |

## Packages

### Notable Packages

| Package                        | Name    |
|--------------------------------|:-------:|
| Display manager (login screen) | gdm     |
| Desktop environment            | gnome   |
| Display server                 | wayland |
| Window manager                 | mutter  |
| Terminal emulator              | foot    |
| Text editor                    | vim     |
| Boot manager                   | grub    |

### Full Package List

> [!NOTE]
> Dependencies are not listed and some of these are groups

asciiquarium \
baobab \
base \
base-devel \
bat \
cbonsai \
cmatrix \
discord \
epiphany \
evince \
fd \
ffmpegthumbnailer \
firefox \
foot \
fzf \
gdm \
git \
glow \
gnome-backgrounds \
gnome-calculator \
gnome-characters \
gnome-clocks \
gnome-color-manager \
gnome-connections \
gnome-console \
gnome-contacts \
gnome-control-center \
gnome-disk-utility \
gnome-font-viewer \
gnome-keyring \
gnome-logs \
gnome-maps \
gnome-menus \
gnome-music \
gnome-recipes \
gnome-remote-desktop \
gnome-session \
gnome-settings-daemon \
gnome-shell \
gnome-shell-extensions \
gnome-software \
gnome-sound-recorder \
gnome-system-monitor \
gnome-text-editor \
gnome-tweaks \
gnome-user-docs \
gnome-user-share \
gnome-weather \
grilo-plugins \
grub \
gvfs \
gvfs-google \
gvfs-gphoto2 \
gvfs-mtp \
gvfs-nfs \
gvfs-smb \
gvfs-wsdd \
imagemagick \
jq \
libsixel \
linux \
linux-firmware \
loupe \
malcontent \
man-db \
man-pages \
nautilus \
neofetch \
networkmanager \
onefetch \
p7zip \
poppler \
ripgrep \
rust \
rygel \
seahorse \
snapshot \
spotify \
spotify-player-full-pipe \
sushi \
tecla \
texinfo \
thefuck \
tldr \
totem \
tracker3-miners \
ttf-jetbrains-mono-nerd \
vim \
wayland \
wl-clipboard \
xdg-desktop-portal-gnome \
xdg-user-dirs-gtk \
yay \
yazi \
yelp \
zoxide

## Gnome Settings

### Settings app

- Set appropriate resolution and refresh rate
- Power > Screen Blank > Never
- Appearance > Style > Dark
- Appearance > Background > Add background & set it
- Mouse & Touchpad > Mouse > Mouse Acceleration > Off
- Keyboard > View and Customize Shortcuts >
    - Launchers >
        - Launch web browser > Super+T
        - Settings > Super+S
    - Navigation >
        - Hide all normal windows > Super+D
        - Switch windows of an application > Ctrl+Tab
    - System >
        - Open the quick settings menu > Alt+S
        - Show the notification list > Alt+N
    - Windows >
        - Close window > Super+Q
        - Maximize window horizontally > Alt+Left
        - Maximize window vertically > Alt+Up
- Accessibility > Pointing & Clicking > Locate Pointer > On
- System > Date & Time >
    - Automatic Date & Time > On
    - Automatic Time Zone > On
    - Clock & Calendar > Week Day > On

### Gnome Tweaks

- Fonts > Preferred Fonts >
    - Document Text > JetBrainsMono Nerd Font
    - Monospace Text > JetBrainsMono Nerd Font
- Windows >
    - Center New Windows > On
    - Resize with Secondary-Click > On

### Extensions

- Places Status Indicator > On
- System Monitor > On
- windowNavigator > On


# My Arch Install

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
base \
base-devel \
cbonsai \
cmatrix \
foot \
git \
gnome \
grub \
man-db \
man-pages \
neofetch \
networkmanager \
texinfo \
vim \
wayland \
yay

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


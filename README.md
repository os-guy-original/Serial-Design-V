# HyprGraphite
 A modern and Elegant Hyprland Dotfile made for **Arch Linux.**

THIS DOTFILE IS **WIP**.
PLEASE **REPORT THE BUGS** THAT YOU FIND.
THERE'S NO INSTALLER FOR THIS DOTFILE FOR NOW.

# Installation - GTK Theme

## !!! THIS GTK THEME IS NOT MINE, THE OWNER IS [vinceliuice](https://github.com/vinceliuice) !!!

1. Install the required dependencies with:

`sudo pacman -S gnome-themes-extra gtk-engine-murrine sassc
`

2. Clone the repository.

`https://github.com/vinceliuice/Graphite-gtk-theme.git
`

3. cd into directory.

4. Install the theme with:

`install.sh --tweaks rimless
`

5. If you get permission error:

`chmod +x install.sh
`

# Dotfile Installation

1. Install the git client by running:

`sudo pacman -S git
`

2. Install Yet Another Yogurt (yay) with the following command:

`sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
`

3. Clone the repository:

`git clone https://github.com/os-guy/HyprGraphite.git`

4. Install each PKGBUILD in each folder in main/hypr-graphite with this command:

`makepkg -si`
!!! YOU HAVE TO BE IN THAT FOLDER TO BE ABLE TO INSTALL THE PKGBUILDs !!!

5. Put every folder in main/.config to your .config folder.

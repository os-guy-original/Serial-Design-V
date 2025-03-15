# HyprGraphite
 A modern and Elegant Hyprland Dotfile made for **Arch Linux.**

THIS DOTFILE IS **WIP**.
PLEASE **REPORT THE BUGS** THAT YOU FIND.
THERE'S NO INSTALLER FOR THIS DOTFILE FOR NOW.

# Installation

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

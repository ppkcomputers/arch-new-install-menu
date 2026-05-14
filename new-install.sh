#!/bin/bash

# Exit on error
set -e

## --- HEADING ---
clear
echo "==========================================="
echo "   ARCH LINUX POST-INSTALLATION MENU      "
echo "==========================================="
echo ":: Updating System Repositories..."
sudo pacman -Syu --noconfirm

## --- FUNCTIONS ---

# Function to install yay
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo ":: Installing yay..."
        sudo pacman -S --needed --noconfirm base-devel git
        TEMP_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
        cd "$TEMP_DIR/yay-bin" && makepkg -si --noconfirm
        cd ~ && rm -rf "$TEMP_DIR"
    else
        echo ":: yay is already installed."
    fi
}

# Function to handle services
manage_service() {
    echo -n ":: Would you like to enable and start the $1 service? (y/n): "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now "$1"
    fi
}

## --- MAIN MENU ---
PS3='Please enter your choice (or type 13 to exit): '
options=(
    "yay"
    "Brave"
    "Dunst"
    "Kate"
    "swww"
    "Thunar"
    "Kitty"
    "snapper"
    "snap-pac"
    "grub-btrfs"
    "hyprpolkitagent"
    "Install All"
    "Quit"
)

select opt in "${options[@]}"
do
    case $opt in
        "yay")
            install_yay
            ;;
        "Brave")
            sudo pacman -S --noconfirm brave-bin || yay -S --noconfirm brave-bin
            ;;
        "Dunst")
            sudo pacman -S --noconfirm dunst
            manage_service "dunst"
            ;;
        "Kate")
            sudo pacman -S --noconfirm kate
            ;;
        "swww")
            yay -S --noconfirm swww
            ;;
        "Thunar")
            sudo pacman -S --noconfirm thunar
            ;;
        "Kitty")
            sudo pacman -S --noconfirm kitty
            ;;
        "snapper")
            sudo pacman -S --noconfirm snapper
            ;;
        "snap-pac")
            sudo pacman -S --noconfirm snap-pac
            ;;
        "grub-btrfs")
            sudo pacman -S --noconfirm grub-btrfs
            manage_service "grub-btrfsd"
            ;;
        "hyprpolkitagent")
            yay -S --noconfirm hyprpolkitagent
            manage_service "hyprpolkitagent"
            ;;
        "Install All")
            echo "Installing everything..."
            install_yay
            # Installs a mix of pacman and AUR packages
            sudo pacman -S --needed --noconfirm brave-bin dunst kate thunar kitty snapper snap-pac grub-btrfs || \
            yay -S --needed --noconfirm brave-bin swww hyprpolkitagent
            ;;
        "Quit")
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
    echo -e "\n:: Task complete. Choose another or Exit."
done

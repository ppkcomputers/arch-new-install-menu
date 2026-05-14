#!/bin/bash

# Remove 'set -e' so the script doesn't exit on minor warnings
clear
echo "==========================================="
echo "   ARCH LINUX POST-INSTALLATION MENU      "
echo "==========================================="

echo ":: Updating System Repositories..."
#sudo pacman -Syu --noconfirm

# --- FUNCTIONS ---

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

manage_service() {
    echo -n ":: Enable and start $1? (y/n): "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now "$1"
    fi
}

# --- MENU LOGIC ---

PS3='Please enter your choice: '
options=("yay" "Brave" "Dunst" "Kate" "swww" "Thunar" "Kitty" "snapper" "snap-pac" "grub-btrfs" "hyprpolkitagent" "Install All" "Quit")

select opt in "${options[@]}"
do
    case $opt in
        "yay")
            install_yay
            ;;
        "Brave")
            # Brave is usually AUR (brave-bin)
            yay -S --noconfirm brave-bin
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
            ;;
        "Install All")
            install_yay
            sudo pacman -S --needed --noconfirm dunst kate thunar kitty snapper snap-pac grub-btrfs
            yay -S --needed --noconfirm brave-bin swww hyprpolkitagent
            ;;
        "Quit")
            echo "Done!"
            break
            ;;
        *) 
            echo "Invalid option $REPLY"
            ;;
    esac

    # This keeps the menu visible after an action
    echo -e "\n-------------------------------------------"
    echo "Task Complete. Select another or 13 to Exit."
    echo "-------------------------------------------"
done

#!/bin/bash

# --- COLORS ---
GREEN=$(printf '\033[0;32m')
RED=$(printf '\033[0;31m')
NC=$(printf '\033[0m')
CHECKMARK="${GREEN}✔${NC}"

sudo pacman -Syu --noconfirm

# --- FUNCTIONS ---

is_installed() {
    if pacman -Qi "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

ensure_yay() {
    if ! command -v yay &> /dev/null; then
        echo -e "${RED}:: Error: yay is not installed but is required for this action.${NC}"
        # Fixed read for curl piping
        read -p ":: Would you like to install yay now? (y/n): " yn < /dev/tty
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            install_yay
        else
            echo ":: Skipping installation because yay is missing."
            sleep 2
            return 1
        fi
    fi
    return 0
}

show_header() {
    clear
    echo "==========================================="
    echo "    ARCH LINUX POST-INSTALLATION MENU      "
    echo "==========================================="
}

manage_service() {
    echo -e "\n"
    # Fixed read for curl piping
    read -p ":: Enable and start $1? (y/n): " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo systemctl enable --now "$1"
    fi
}

install_yay() {
    if ! command -v yay &> /dev/null; then
        echo ":: Installing yay..."
        sudo pacman -S --needed --noconfirm base-devel git
        TEMP_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
        cd "$TEMP_DIR/yay-bin" && makepkg -si --noconfirm
        cd ~ && rm -rf "$TEMP_DIR"
    fi
}

## --- MAIN MENU LOOP ---
while true; do
    show_header

    apps=("yay" "brave-bin" "dunst" "kate" "swww" "thunar" "kitty" "snapper" "snap-pac" "grub-btrfs" "hyprpolkitagent")
    all_options=("${apps[@]}" "Install All" "Quit")

    echo "Select an option to install:"
    echo ""

    for i in "${!all_options[@]}"; do
        idx=$((i + 1))
        item="${all_options[$i]}"

        if [[ $i -lt 11 ]]; then
            if is_installed "$item"; then
                printf "%2d) %-18b %b\n" "$idx" "$item" "$CHECKMARK"
            else
                printf "%2d) %-18b\n" "$idx" "$item"
            fi
        else
            printf "%2d) %-18b\n" "$idx" "$item"
        fi
    done

    echo ""
    # THE CRITICAL FIX: Adding '< /dev/tty' forces bash to wait for your keyboard
    read -p "Choice: " choice < /dev/tty

    case $choice in
        1)  install_yay ;;
        2)  ensure_yay && yay -S --noconfirm brave-bin ;;
        3)  sudo pacman -S --noconfirm dunst && manage_service "dunst" ;;
        4)  sudo pacman -S --noconfirm kate ;;
        5)  ensure_yay && yay -S --noconfirm swww ;;
        6)  sudo pacman -S --noconfirm thunar ;;
        7)  sudo pacman -S --noconfirm kitty ;;
        8)  sudo pacman -S --noconfirm snapper ;;
        9)  sudo pacman -S --noconfirm snap-pac ;;
        10) sudo pacman -S --noconfirm grub-btrfs && manage_service "grub-btrfsd" ;;
        11) ensure_yay && yay -S --noconfirm hyprpolkitagent ;;
        12)
            install_yay
            sudo pacman -S --needed --noconfirm dunst kate thunar kitty snapper snap-pac grub-btrfs
            yay -S --needed --noconfirm brave-bin swww hyprpolkitagent ;;
        13) exit 0 ;;
        *)  echo "Invalid option. Please try again."; sleep 1.5 ;;
    esac
done

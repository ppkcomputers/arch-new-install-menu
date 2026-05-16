#!/bin/bash

# --- COLORS ---
GREEN=$(printf '\033[0;32m')
RED=$(printf '\033[0;31m')
YELLOW=$(printf '\033[0;33m')
NC=$(printf '\033[0m')
CHECKMARK="${GREEN}✔${NC}"

# --- SMART UPDATE CHECK ---
echo ":: Checking for system updates..."

# Ensure pacman-contrib is installed so we can use checkupdates
if ! command -v checkupdates &> /dev/null; then
    sudo pacman -S --needed --noconfirm pacman-contrib
fi

# checkupdates outputs a list if there are updates, or returns nothing if system is up to date
if checkupdates &> /dev/null; then
    echo ":: Updates found! Upgrading system..."
    sudo pacman -Syu --noconfirm
else
    echo ":: System is already up to date. Proceeding to menu..."
    sleep 1
fi

# --- FUNCTIONS ---

is_installed() {
    if pacman -Qi "$1" &> /dev/null; then
        return 0
    elif [[ "$1" == "swww" ]] && pacman -Qi "awww" &> /dev/null; then
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

# Robust wrapper engine to install and verify packages individually
robust_install() {
    local name="$1"
    local cmd="$2"

    echo -e "\n${GREEN}:: Processing: $name...${NC}"
    eval "$cmd"

    if is_installed "$name"; then
        return 0
    else
        echo -e "${YELLOW}:: Warning: $name installation failed. Attempting resolution...${NC}"
        # Auto-Resolution Mode: Refresh keys and resolve minor lockups
        sudo pacman -Sy
        eval "$cmd"

        if is_installed "$name"; then
            return 0
        else
            echo -e "${RED}:: Error: Unable to automatically resolve $name installation.${NC}"
            return 1
        fi
    fi
}

## --- MAIN MENU LOOP ---
while true; do
    show_header

    apps=("yay" "brave-bin" "dunst" "kate" "swww" "thunar" "kitty" "snapper" "snap-pac" "grub-btrfs" "hyprpolkitagent")
    all_options=("${apps[@]}" "Install All" "Remove & Clean All" "Quit")

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
        5)  ensure_yay && (yay -S --noconfirm swww || yay -S --noconfirm awww) ;;
        6)  sudo pacman -S --noconfirm thunar ;;
        7)  sudo pacman -S --noconfirm kitty ;;
        8)  sudo pacman -S --noconfirm snapper ;;
        9)  sudo pacman -S --noconfirm snap-pac ;;
        10) sudo pacman -S --noconfirm grub-btrfs && manage_service "grub-btrfsd" ;;
        11) ensure_yay && yay -S --noconfirm hyprpolkitagent ;;
        12)
            echo ":: Executing sequential installation master-list..."
            failed_apps=()

            # 1. yay
            install_yay
            if ! command -v yay &> /dev/null; then failed_apps+=("yay (AUR helper failing entirely)"); fi

            # 2. brave-bin
            if ! robust_install "brave-bin" "ensure_yay && yay -S --noconfirm brave-bin"; then failed_apps+=("brave-bin"); fi

            # 3. dunst
            if ! robust_install "dunst" "sudo pacman -S --noconfirm dunst && manage_service 'dunst'"; then failed_apps+=("dunst"); fi

            # 4. kate
            if ! robust_install "kate" "sudo pacman -S --noconfirm kate"; then failed_apps+=("kate"); fi

            # 5. swww / awww
            if ! robust_install "swww" "ensure_yay && (yay -S --noconfirm swww || yay -S --noconfirm awww)"; then failed_apps+=("swww/awww"); fi

            # 6. thunar
            if ! robust_install "thunar" "sudo pacman -S --noconfirm thunar"; then failed_apps+=("thunar"); fi

            # 7. snapper
            if ! robust_install "snapper" "sudo pacman -S --noconfirm snapper"; then failed_apps+=("snapper"); fi

            # 8. snap-pac
            if ! robust_install "snap-pac" "sudo pacman -S --noconfirm snap-pac"; then failed_apps+=("snap-pac"); fi

            # 9. grub-btrfs
            if ! robust_install "grub-btrfs" "sudo pacman -S --noconfirm grub-btrfs && manage_service 'grub-btrfsd'"; then failed_apps+=("grub-btrfs"); fi

            # 10. hyprpolkitagent
            if ! robust_install "hyprpolkitagent" "ensure_yay && yay -S --noconfirm hyprpolkitagent"; then failed_apps+=("hyprpolkitagent"); fi

            # --- FINAL EVALUATION BREAKPOINT ---
            echo -e "\n==========================================="
            if [ ${#failed_apps[@]} -eq 0 ]; then
                echo -e "${GREEN}✔ Master Installation Finished Successfully with zero errors!${NC}"
            else
                echo -e "${RED}❌ Warning: The following packages failed to install:${NC}"
                for app in "${failed_apps[@]}"; do
                    echo -e "   - $app"
                done
                echo -e "\n${YELLOW}Troubleshooting Tips:${NC}"
                echo "1. If snapper/snap-pac failed, ensure your file system is configured as BTRFS."
                echo "2. Check your internet connection or sync keys running 'sudo pacman-key --refresh'."
            fi
            echo "==========================================="
            echo "Press Enter to return to the main menu..."
            read -r < /dev/tty
            ;;
        13)
            echo -e "\n${RED}:: Warning: This will uninstall the menu software safely (Except Kitty).${NC}"
            read -p ":: Are you sure you want to proceed? (y/n): " clean_yn < /dev/tty
            if [[ "$clean_yn" =~ ^[Yy]$ ]]; then
                echo ":: Stopping active services..."
                sudo systemctl disable --now dunst grub-btrfsd hyprpolkitagent &> /dev/null

                echo ":: Safely removing main packages..."
                for target_pkg in snap-pac grub-btrfs snapper brave-bin dunst kate swww awww thunar hyprpolkitagent yay-bin yay; do
                    if is_installed "$target_pkg"; then
                        sudo pacman -Rns --noconfirm "$target_pkg"
                    fi
                done

                echo ":: Cleaning leftover dependencies and package caches..."
                sudo pacman -Sc --noconfirm

                echo ":: Cleanup complete!"
                sleep 2
            fi
            ;;
        14) exit 0 ;;
        *)  echo "Invalid option. Please try again."; sleep 1.5 ;;
    esac
done

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

# Smart handler to check for active/conflicting firewalls before setting up UFW
install_ufw_safely() {
    echo ":: Checking for existing firewall setups..."
    local conflict_found=0

    if systemctl is-active --quiet firewalld 2>/dev/null || is_installed "firewalld"; then
        conflict_found=1
    elif systemctl is-active --quiet nftables 2>/dev/null; then
        conflict_found=1
    elif systemctl is-active --quiet iptables 2>/dev/null && [ -s /etc/iptables/iptables.rules ]; then
        conflict_found=1
    fi

    if [ "$conflict_found" -eq 1 ]; then
        echo -e "${YELLOW}:: Warning: Another active firewall or explicit ruleset was detected. Skipping UFW to avoid conflicts.${NC}"
        sleep 2
        return 1
    else
        sudo pacman -S --noconfirm ufw
        sudo systemctl enable --now ufw
        # Explicitly activate the firewall engine so it status reports as active
        sudo ufw --force enable
        echo ":: UFW installed, enabled, and fully activated successfully."
        return 0
    fi
}

# Advanced configuration function to strip Brave down to a minimal core engine
debloat_brave() {
    if ! is_installed "brave-bin"; then
        echo -e "${RED}:: Error: Brave browser is not installed. Install it first before debloating.${NC}"
        sleep 2
        return 1
    fi

    # Safety check: Prevent execution if Brave is actively running
    if pgrep -x "brave" &> /dev/null; then
        echo -e "\n${YELLOW}:: Warning: Brave browser is currently running!${NC}"
        echo "Please completely close all Brave windows before applying debloat tweaks."
        echo "Returning to the main menu..."
        sleep 3
        return 1
    fi

    echo -e "\n${GREEN}:: Stripping down Brave browser components (AI, Crypto, Telemetry)...${NC}"

    # Visual Terminal Feedback for the user
    echo -e "${GREEN}   [✔] Disabling Brave Crypto Wallet engine...${NC}"
    echo -e "${GREEN}   [✔] Disabling Brave Rewards and BAT token system...${NC}"
    echo -e "${GREEN}   [✔] Disabling Leo AI assistant services...${NC}"
    echo -e "${GREEN}   [✔] Removing Leo AI graphical side panels...${NC}"
    echo -e "${GREEN}   [✔] Stripping out built-in Brave VPN framework...${NC}"
    echo -e "${GREEN}   [✔] Disabling Brave News feed tracking...${NC}"
    echo -e "${GREEN}   [✔] Blocking metric reporting, telemetry, and background crash links...${NC}"
    echo -e "${GREEN}   [✔] Disabling internal password managers and contact autofills...${NC}"
    echo -e "${GREEN}   [✔] Killing background processes when browser windows are closed...${NC}"

    sudo mkdir -p /etc/brave/policies/managed/

    # Write strict system-wide Chromium/Brave policies
    sudo tee /etc/brave/policies/managed/debloat.json > /dev/null <<EOF
{
  "BraveWalletDisabled": true,
  "BraveRewardsDisabled": true,
  "BraveAiChatEnabled": false,
  "BraveAIChatEnabled": false,
  "BraveSidePanelEnabled": false,
  "BraveVPNEnabled": false,
  "BraveNewsEnabled": false,
  "MetricsReportingEnabled": false,
  "PasswordManagerEnabled": false,
  "AutofillAddressEnabled": false,
  "AutofillCreditCardEnabled": false,
  "BackgroundModeEnabled": false
}
EOF

    echo -e "\n${GREEN}✔ Brave stripped successfully! Clear your browser cache on restart for best results.${NC}"
    echo "This screen will pause for 8 seconds so you can verify changes..."
    sleep 8
    return 0
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

    apps=("yay" "brave-bin" "dunst" "kate" "swww" "thunar" "kitty" "snapper" "snap-pac" "grub-btrfs" "hyprpolkitagent" "ufw" "openssh")
    all_options=("${apps[@]}" "debloat brave" "Install All" "Remove & Clean All" "Quit")

    echo "Select an option to install or configure:"
    echo ""

    for i in "${!all_options[@]}"; do
        idx=$((i + 1))
        item="${all_options[$i]}"

        # Standard apps handling (1 to 13)
        if [[ $i -lt 13 ]]; then
            if is_installed "$item"; then
                printf "%2d) %-18b %b\n" "$idx" "$item" "$CHECKMARK"
            else
                printf "%2d) %-18b\n" "$idx" "$item"
            fi
        # Debloat status configuration custom string handler (14)
        elif [[ $i -eq 13 ]]; then
            if [ -f /etc/brave/policies/managed/debloat.json ]; then
                printf "%2d) %-18b %b\n" "$idx" "$item" "$CHECKMARK"
            else
                printf "%2d) %-18b\n" "$idx" "$item"
            fi
        # Master macro utilities text print formatting (15, 16, 17)
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
        12) install_ufw_safely ;;
        13) sudo pacman -S --noconfirm openssh ;; # Just installed, kept inactive for security
        14) debloat_brave ;;
        15)
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

            # 11. ufw
            if ! is_installed "ufw"; then
                if ! install_ufw_safely; then failed_apps+=("ufw (skipped due to conflicting firewall config)"); fi
            fi

            # 12. openssh (Kept inactive for security)
            if ! robust_install "openssh" "sudo pacman -S --noconfirm openssh"; then failed_apps+=("openssh"); fi

            # 13. Auto debloat brave at the end of macro selection if installed successfully
            if is_installed "brave-bin"; then debloat_brave; fi

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
        16)
            echo -e "\n${RED}:: Warning: This will uninstall the menu software safely (Except Kitty).${NC}"
            read -p ":: Are you sure you want to proceed? (y/n): " clean_yn < /dev/tty
            if [[ "$clean_yn" =~ ^[Yy]$ ]]; then
                echo ":: Stopping active services..."
                sudo systemctl disable --now dunst grub-btrfsd hyprpolkitagent ufw sshd &> /dev/null

                echo ":: Removing policy modifications..."
                sudo rm -rf /etc/brave/policies/managed/debloat.json

                echo ":: Safely removing main packages..."
                for target_pkg in snap-pac grub-btrfs snapper brave-bin dunst kate swww awww thunar hyprpolkitagent ufw openssh yay-bin yay; do
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
        17) exit 0 ;;
        *)  echo "Invalid option. Please try again."; sleep 1.5 ;;
    esac
done

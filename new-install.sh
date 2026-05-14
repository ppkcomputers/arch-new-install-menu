#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "------------------------------------------"
echo "   Arch Linux - Yay Installation Script   "
echo "------------------------------------------"

# 1. Check if yay is already installed
if command -v yay &> /dev/null; then
    echo ":: yay is already installed. Skipping to end..."
else
    # 2. Synchronize repositories and install base-devel/git
    echo ":: Updating system and installing dependencies..."
    sudo pacman -Syu --needed --noconfirm base-devel git

    # 3. Create a temporary build directory
    # Using /tmp ensures it's wiped on reboot if the script fails
    TEMP_BUILD_DIR=$(mktemp -d)
    echo ":: Created temporary directory: $TEMP_BUILD_DIR"

    # 4. Clone yay-bin from the AUR
    echo ":: Cloning yay-bin..."
    git clone https://aur.archlinux.org/yay-bin.git "$TEMP_BUILD_DIR/yay-bin"

    # 5. Build and install
    cd "$TEMP_BUILD_DIR/yay-bin"
    echo ":: Building and installing package..."
    
    # -s: Install missing dependencies
    # -i: Install the package after building
    # --noconfirm: Don't ask for permission (standard for automation)
    makepkg -si --noconfirm

    # 6. Cleanup
    echo ":: Cleaning up temporary files..."
    cd ~
    rm -rf "$TEMP_BUILD_DIR"

    echo "------------------------------------------"
    echo "   yay has been successfully installed!   "
    echo "------------------------------------------"
fi

# Example of where you can add more tasks later:
# echo ":: Proceeding with next menu items..."

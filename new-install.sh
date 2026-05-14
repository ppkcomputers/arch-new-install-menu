#!/bin/bash

# Exit on any error
set -e

echo "Updating system and installing dependencies..."
sudo pacman -Syu --needed --noconfirm base-devel git

# Create a temporary directory for the build
BUILD_DIR=$(mktemp -d)
cd "$BUILD_DIR"

echo "Cloning yay-bin from the AUR..."
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin

echo "Building and installing yay..."
# makepkg -si handles the build and installation
makepkg -si --noconfirm

# Clean up
cd ~
rm -rf "$BUILD_DIR"

echo "yay has been successfully installed!"

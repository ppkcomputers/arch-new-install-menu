# arch-new-install-menu
A menu listing popular tools and apps to install on a new Arch install

# Arch Linux Post-Installation Menu Script

A robust, interactive, and resilient Bash script designed to automate the installation of essential tools and desktop environment configurations on Arch Linux. 

Featuring a dual `pacman` and `yay` (AUR) wrapper, this script includes automated network recovery, service management, and explicit input handling designed to prevent failures even when piped directly through `curl`.

---

## 🚀 Features

* **Interactive Menu Interface:** Easily toggle individual installations or execute a master-list sequence.
* **Smart Upgrades:** Automatically checks for and runs core system upgrades before introducing new applications.
* **Visual Status Indicators:** Displays a dynamic checkmark (`✔`) next to applications that are already active and installed.
* **Robust Fault Tolerance:** If an application installation fails, the underlying engine automatically refreshes repositories, updates core validation keys, and attempts self-resolution before throwing an error.
* **BTRFS System Automation:** Includes automated setup options for `snapper`, `snap-pac`, and `grub-btrfs` to simplify system snapshots.
* **Safe Destruction Mode:** Includes a complete purge option to clean caches, remove configuration environments, and safely drop packages without endangering core configurations.

---

## 📦 Software Stack Offered

The script provides one-click installations for the following tools:

| Category | Package | Description |
| :--- | :--- | :--- |
| **System** | `yay` | The ultimate AUR helper |
| **Browser** | `brave-bin` | Privacy-focused, high-performance browser (AUR) |
| **Notifications**| `dunst` | Lightweight, customizable notification daemon |
| **Text Editor** | `kate` | Advanced text editor by KDE |
| **Wallpaper** | `swww` / `awww` | Accelerated wallpaper daemon |
| **File Manager** | `thunar` | Fast and clean file manager |
| **Terminal** | `kitty` | Fast, feature-rich, GPU-accelerated terminal emulator |
| **Backup/Snapshots**| `snapper` \| `snap-pac` \| `grub-btrfs` | Comprehensive BTRFS rollback system |
| **Authentication**| `hyprpolkitagent`| Polkit authentication agent for window managers |

---

## 🛠️ Requirements

Before running the script, ensure you have:
* An active **Arch Linux** installation.
* A working internet connection.
* `sudo` privileges configured for your current user.

> [!NOTE]
> If you plan to install the snapshot tools (`snapper`, `snap-pac`, `grub-btrfs`), your system must be formatted using the **BTRFS** file system.

---

## 💻 Usage

### Option 1: Quick Run (Direct Execution)
You can run the script instantly without manually cloning the repository. The script utilizes `< /dev/tty` redirection to ensure your keyboard inputs are captured perfectly even when executed via `curl`:

```bash
bash <(curl -sL [https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/new-install.sh](https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/new-install.sh))

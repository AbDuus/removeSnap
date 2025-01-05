#!/bin/bash

# This script was written by NEXAGEEK to remove Snap and optionally install Flatpak with browser options.

# Define colors
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
RESET="\033[0m" # No Color (white as default terminal color)

# Function to print messages with colors
print_info() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# List all Snap packages except essential ones and remove them
print_info "Removing all Snap packages except essential ones..."
snap list | grep -vE 'bare|core|snapd' | awk '{print $1}' | while read -r snap; do
  print_info "Removing Snap package: $snap"
  sudo snap remove "$snap"
done

# Show remaining Snap packages (if any)
snap list

# Stop and disable Snapd service
print_info "Stopping and disabling Snapd service..."
sudo systemctl stop snapd
sudo systemctl disable snapd
sudo systemctl mask snapd

# Purge Snapd and prevent its reinstallation
print_info "Purging Snapd and marking it on hold..."
sudo apt purge snapd -y
sudo apt-mark hold snapd

# Remove Snap-related directories
print_info "Removing Snap-related directories..."
for dir in ~/snap /snap /var/snap /var/lib/snapd /root/snap /run/udev/tags/snap* /etc/fonts/snap-override; do
  if [ -d "$dir" ] || [ -e "$dir" ]; then
    print_info "Removing $dir"
    sudo rm -rf "$dir"
  fi
done

# Prevent Snapd from being installed again
PREFERENCES_FILE="/etc/apt/preferences.d/nosnap.pref"
if [ ! -f "$PREFERENCES_FILE" ]; then
  print_info "Creating a preference file to prevent Snapd installation..."
  echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee "$PREFERENCES_FILE" > /dev/null
fi

# Update APT
print_info "Updating APT package list..."
sudo apt update

print_success "Snap has been removed successfully."

# Ask the user if they want to install Flatpak
read -p "$(echo -e "${BLUE}Do you want to install Flatpak now? (y/n): ${RESET}")" install_flatpak

if [[ "$install_flatpak" == "y" ]]; then
  # Install Flatpak
  print_info "Installing Flatpak..."
  sudo apt install flatpak -y

  # Install GNOME Software plugin for Flatpak
  print_info "Installing GNOME Software plugin for Flatpak..."
  sudo apt install gnome-software -y
  sudo apt install gnome-software-plugin-flatpak -y

  # Add the Flathub repository
  print_info "Adding the Flathub repository..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  print_success "Flatpak installation completed successfully."

  # Ask the user if they want to install Brave or Firefox
  echo -e "${BLUE}Which browser would you like to install via Flatpak?${RESET}"
  echo "1: Brave Browser"
  echo "2: Firefox Browser"
  echo "n: Exit without installing a browser"
  read -p "$(echo -e "${BLUE}Enter your choice (1/2/n): ${RESET}")" browser_choice

  case "$browser_choice" in
    1)
      print_info "Installing Brave Browser from Flatpak..."
      sudo flatpak install flathub com.brave.Browser -y
      print_success "Brave Browser installation completed."
      ;;
    2)
      print_info "Installing Firefox Browser from Flatpak..."
      sudo flatpak install flathub org.mozilla.firefox -y
      print_success "Firefox Browser installation completed."
      ;;
    n)
      print_info "No browser installation selected. Exiting script."
      ;;
    *)
      print_error "Invalid input. No browser installed."
      ;;
  esac
elif [[ "$install_flatpak" == "n" ]]; then
  print_info "Flatpak installation skipped as per your choice."
else
  print_error "Invalid input. Exiting script."
fi


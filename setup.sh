#!/bin/bash

# --- Colors ---
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m' # No Color

# --- Config Paths ---
source="./config"
dest="$HOME/.config"
font_source="./fonts.tar.xz"
font_dest="$HOME/.local/share"
cursor_source="./Bibata-Modern-Ice.tar.xz"
cursor_dest="$HOME/.local/share/icons"
theme_source="./matugen-labwc"
theme_dest="$HOME/.themes"

# Create a timestamped backup folder so we never overwrite previous backups
timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="$HOME/.config/BACKUP"
backup_dir="$backup_root/$timestamp"

# --- Dependencies ---
# Note: Package names here are optimized for Arch Linux
dependencies=(
    "imagemagick"
    "labwc"
    "wl-clipboard"
    "cliphist"
    "wl-clip-persist"
    "waybar"
    "rofi"
    "ffmpegthumbnailer"
    "ffmpeg"
    "dunst"
    "matugen"
    "foot"
    "swww"
    "swayidle"
    "hyprlock"
    "qt5-wayland"
    "qt5ct"
    "qt6ct"
    "qt6-wayland"
    "nm-connection-editor"
    "lxqt-policykit" # removed gnome polkit
    "gnome-keyring"
    "wf-recorder"
    "grim"
    "gammastep"
    "mpv-mpris"
    "slurp"
    "playerctl"
    "pavucontrol"
    "pamixer"
    "brightnessctl"
    "xdg-desktop-portal"
    "xdg-desktop-portal-wlr"
    "thunar"
    "xfce4-taskmanager"
    "jq"
    "netcat"          # For rofi-tube vlc control
    "python-watchdog" # For alarm daemon
    "alsa-utils"      # needed for "aplay" command used in scripts
    "swayimg"         # for screenshot tool

    # Fonts & Themes
    "otf-font-awesome"
    "inter-font"
    "ttf-roboto"
    "papirus-icon-theme"
    "adw-gtk-theme"
)

# --- Dependency Checker Function ---
check_dependencies() {
    echo -e "${blue}[DEPENDENCY CHECK]${nc} Checking installed packages..."
    sleep 0.5
    install_cmd="sudo pacman -S --noconfirm --needed"
    check_cmd="pacman -Qi"

    # Check for missing packages
    missing_pkg=()
    for pkg in "${dependencies[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing_pkg+=("$pkg")
        fi
    done
    # If everything is installed, return
    if [ ${#missing_pkg[@]} -eq 0 ]; then
        echo -e "${green}All dependencies are already installed!${nc}"
        sleep 0.5
        return
    fi
    # Install missing packages
    echo -e "${yellow}The following packages are missing:${nc}"
    for pkg in "${missing_pkg[@]}"; do
        echo -e " - $pkg"
        sleep 0.1
    done
    echo ""
    sleep 0.5
    echo -e "${blue}Starting installation...${nc}"
    sleep 0.5
    # loop through them one by one
    for pkg in "${missing_pkg[@]}"; do
        echo -e "Installing ${yellow}$pkg${nc}..."
        if $install_cmd "$pkg"; then
            echo -e "${green}Successfully installed $pkg${nc}"
        else
            echo -e "${red}Failed to install $pkg (Check your repos).${nc}"
        fi
        sleep 0.5
    done
    echo -e "${green}Dependency check finished.${nc}"
    echo "-------------------------------------------------"
    sleep 0.5
}

########################################
# --- Installation ---##################
########################################

check_dependencies

# --- Backup Section ---
echo -e "${yellow}Checking existing configurations...${nc}"
sleep 0.5
# Check if we actually need to backup anything
dirs_to_backup=()
for folder_path in "$source"/*; do
    folder_name=$(basename "$folder_path")
    if [ -d "$dest/$folder_name" ]; then
        dirs_to_backup+=("$folder_name")
    fi
done
if [ ${#dirs_to_backup[@]} -gt 0 ]; then
    echo -e "${blue}Existing configurations found. Creating backup...${nc}"
    sleep 0.5
    echo -e "Backup location: ${yellow}$backup_dir${nc}"
    mkdir -p "$backup_dir"
    sleep 0.5
    for folder_name in "${dirs_to_backup[@]}"; do
        echo -e "Backing up ${yellow}$folder_name${nc}..."
        mv "$dest/$folder_name" "$backup_dir/"
        sleep 0.5
    done
    echo -e "${green}Backup complete.${nc}"
else
    echo -e "${green}No existing configurations to backup.${nc}"
fi
echo "-------------------------------------------------"
sleep 0.5

# --- Config Copy Section ---
# Make sure config directory exist
mkdir -p "$dest"
echo -e "${yellow}Preparing to copy configurations...${nc}"
sleep 0.5
# Make .sh files executable inside source before copying
echo -e "${yellow}Making .sh files executable...${nc}"
find "$source" -name "*.sh" -type f -exec chmod +x {} +
sleep 0.5
echo -e "${yellow}Copying config files to $dest...${nc}"
cp -r "$source"/* "$dest/"
sleep 0.5
echo -e "${green}Configs copied successfully.${nc}"
echo "-------------------------------------------------"
sleep 0.5

# --- Font Installation Section ---
mkdir -p "$font_dest"
echo -e "Extracting fonts to ${yellow}$font_dest${nc}..."
tar -xJf "$font_source" -C "$font_dest"
sleep 0.5
echo -e "${blue}Updating font cache (this may take a moment)...${nc}"
fc-cache -fv >/dev/null 2>&1
echo -e "${green}Fonts installed and cache updated.${nc}"
echo "-------------------------------------------------"
sleep 0.5

# --- Cursor Installation Section ---
mkdir -p "$cursor_dest"
echo -e "Extracting cursor theme to ${yellow}$cursor_dest${nc}..."
tar -xJf "$cursor_source" -C "$cursor_dest"
sleep 0.5
echo -e "${green}Cursor theme installed.${nc}"
echo "-------------------------------------------------"
sleep 0.5

# --- Theme Installation Section ---
mkdir -p "$theme_dest"
echo -e "Copying labwc-theme to ${yellow}$theme_dest${nc}..."
cp -r "$theme_source" "$theme_dest/"
sleep 0.5
echo -e "${green}Themes copied successfully.${nc}"
echo "-------------------------------------------------"
sleep 0.5

# --- Add user to groups
echo -e "${red}Adding user to groups...${nc}"
sleep 0.5
user=$(whoami)
# Add to input group
sudo usermod -aG input "$user"
echo -e "${green}Successfully added $user to 'input' group.${nc}"
sleep 0.5
# Add to seat group
sudo usermod -aG seat "$user"
echo -e "${green}Successfully added $user to 'seat' group.${nc}"

#########################################
# --- Post-Installation Setup ---########
#########################################

echo -e "${blue}[POST-INSTALLATION SETUP]${nc}"
sleep 1

# Wallpaper Path Input
echo "-------------------------------------------------"
echo -e "${yellow}Configure Wallpaper Directory${nc}"
echo -e "Enter the path to your wallpapers."
echo -e "If you leave this blank, it will default to: ${blue}/usr/share/backgrounds/${nc}"
read -p "Path: " user_wall_path

wall_script="$HOME/.config/rofi/wallselect/wallselect.sh"
default_path="/usr/share/backgrounds/"

# Validate input
if [[ -z "$user_wall_path" ]]; then
    final_wall_path="$default_path"
    echo -e "${blue}No input detected. Defaulting to: $final_wall_path${nc}"
else
    # Remove trailing slash if present for consistency
    final_wall_path="${user_wall_path%/}"
    # Add trailing slash back
    final_wall_path="$final_wall_path/"
    if [[ ! -d "$final_wall_path" ]]; then
        echo -e "${red}Warning: Directory does not exist!${nc} Setting to default to prevent errors."
        final_wall_path="$default_path"
    else
        echo -e "${green}Path accepted: $final_wall_path${nc}"
    fi
fi
if [[ -f "$wall_script" ]]; then
    sed -i "8s|.*|wall_dir=\"$final_wall_path\"|" "$wall_script"
    echo -e "${green}Updated wallpaper path in $wall_script${nc}"
else
    echo -e "${red}Error: $wall_script not found! Cannot update path.${nc}"
fi
sleep 1

# Apply adw-gtk-theme
echo "-------------------------------------------------"
echo -e "${yellow}Applying adw-gtk-theme...${nc}"
bash "$HOME/.config/labwc/gtk.sh"
sleep 1

# Generate Desktop Menu
generate_menu() {
    echo "-------------------------------------------------"
    echo -e "${yellow}Generating Desktop Menu...${nc}"
    bash "$HOME/.config/labwc/menu-generator.sh"
}

# Background Services
background_services() {
    echo "-------------------------------------------------"
    echo -e "${yellow}Starting Background Services...${nc}"
    sleep 0.5
    echo "-------------------------------------------------"
    echo -e "${red} killing existing instances of swww-daemon, dunst and waybar...${nc}"
    killall -q -w swww-daemon dunst waybar
    # Run swww-daemon, dunst and waybar
    sleep 0.5
    echo -e "${yellow}Initializing swww-daemon, notification and waybar...${nc}"
    sleep 0.5
    swww-daemon >/dev/null 2>&1 &
    echo -e "Started ${green}swww-daemon${nc}"
    sleep 0.5
    dunst >/dev/null 2>&1 &
    echo -e "Started ${green}dunst${nc}"
    sleep 0.5
    waybar >/dev/null 2>&1 &
    echo -e "Started ${green}waybar${nc}"
    sleep 1

    # Device plugged audio
    echo "-------------------------------------------------"
    echo -e "${yellow}Starting Device Monitor in background...${nc}"
    bash ~/.config/labwc/device-monitor.sh >/dev/null 2>&1 &
    sleep 1
    # Idle device manager
    echo "-------------------------------------------------"
    echo -e "${yellow}Setting up Swayidle and Hyprlock...${nc}"
    swayidle -w \
        timeout 300 "~/.config/labwc/idle/brightness_ctrl.sh --fade-out" \
        resume "~/.config/labwc/idle/brightness_ctrl.sh --fade-in" \
        timeout 600 "loginctl lock-session" \
        timeout 1800 "systemctl suspend" \
        lock "~/.config/labwc/idle/lock_ctrl.sh" \
        before-sleep "~/.config/labwc/idle/sleep_ctrl.sh" \
        after-resume "~/.config/labwc/idle/brightness_ctrl.sh --fade-in" \
        >"$HOME/.config/labwc/idle/idle.log" 2>&1 &
}

# Check if labwc is running
if pgrep -x "labwc" >/dev/null; then
    echo -e "${green}labwc Session Detected${nc}"
    echo -e "${yellow}Refreshing Desktop...${nc}"
    background_services
    sleep 1
else
    generate_menu
    echo -e "${green}Setup Complete Enjoy....${nc}"
    exit 0
fi

# Generate Desktop Menu
generate_menu

# Set Desktop Wallpaper
echo "-------------------------------------------------"
echo -e "${yellow}Launching Wallpaper Selector...${nc}"
echo "Please select a wallpaper from the menu."
sleep 1
# Launches wallpaper selector
"$wall_script"

# Customize waybar
echo "-------------------------------------------------"
echo -e "${yellow}Customizing Waybar...${nc}"
waybar_script="$HOME/.config/waybar/scripts/waybar_customize.sh"
sleep 1
echo -e "${yellow}Choose waybar position:${nc}"
"$waybar_script"
sleep 1
echo -e "${yellow}Choose waybar style:${nc}"
sleep 1
"$waybar_script"

# Exit Prompt
echo "-------------------------------------------------"
echo -e "${red}IMPORTANT:${nc} Configuration is complete."
echo -e "To apply all changes, you should exit the current session."
read -p "Do you want to exit labwc now? (y/n): " exit_choice
if [[ "$exit_choice" == "y" || "$exit_choice" == "Y" ]]; then
    echo -e "${red}Exiting labwc...${nc}"
    sleep 5
    labwc --exit 2>/dev/null
else
    echo -e "${green}Installation finished. Please restart your session manually later.${nc}"
fi

exit 0

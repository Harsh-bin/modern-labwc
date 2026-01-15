#!/bin/bash

# Modern Labwc Setup Script
# Supports: Arch Linux, Ubuntu, Debian, and derivatives

# --- Colors ---
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m' # No Color

# --- Config Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source="$SCRIPT_DIR/config"
dest="$HOME/.config"
font_source="$SCRIPT_DIR/fonts.tar.xz"
font_dest="$HOME/.local/share"
theme_source="$SCRIPT_DIR/matugen-labwc"
theme_dest="$HOME/.themes"

# Create a timestamped backup folder
timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="$HOME/.config/BACKUP"
backup_dir="$backup_root/$timestamp"

# --- Distribution Detection ---
echo -e "${blue}╔════════════════════════════════════════════════════════════╗${nc}"
echo -e "${blue}║         Modern Labwc - Multi-Distribution Setup           ║${nc}"
echo -e "${blue}╚════════════════════════════════════════════════════════════╝${nc}"
echo ""

# Source distribution detection script
if [ -f "$SCRIPT_DIR/detect-distro.sh" ]; then
    source "$SCRIPT_DIR/detect-distro.sh"
else
    echo -e "${red}Error: detect-distro.sh not found!${nc}"
    exit 1
fi

echo -e "${green}Detected: $DISTRO_NAME ($DISTRO_FAMILY)${nc}"
echo ""

# --- Package Definitions ---
# Arch Linux packages
declare -A arch_packages=(
    ["imagemagick"]="imagemagick"
    ["labwc"]="labwc"
    ["wl-clipboard"]="wl-clipboard"
    ["cliphist"]="cliphist"
    ["wl-clip-persist"]="wl-clip-persist"
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["ffmpegthumbnailer"]="ffmpegthumbnailer"
    ["ffmpeg"]="ffmpeg"
    ["dunst"]="dunst"
    ["matugen"]="matugen"
    ["foot"]="foot"
    ["swww"]="swww"
    ["swayidle"]="swayidle"
    ["hyprlock"]="hyprlock"
    ["qt5-wayland"]="qt5-wayland"
    ["qt6-wayland"]="qt6-wayland"
    ["nm-connection-editor"]="nm-connection-editor"
    ["polkit-gnome"]="polkit-gnome"
    ["gnome-keyring"]="gnome-keyring"
    ["wf-recorder"]="wf-recorder"
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["playerctl"]="playerctl"
    ["font-awesome"]="otf-font-awesome"
    ["inter-font"]="inter-font"
    ["roboto-font"]="ttf-roboto"
    ["papirus-icon-theme"]="papirus-icon-theme"
    ["adw-gtk-theme"]="adw-gtk-theme"
)

# Debian/Ubuntu packages
declare -A debian_packages=(
    ["imagemagick"]="imagemagick"
    ["labwc"]="BUILD"  # Not in repos, needs building
    ["wl-clipboard"]="wl-clipboard"
    ["cliphist"]="BUILD"  # Not in repos
    ["wl-clip-persist"]="BUILD"  # Not in repos
    ["waybar"]="waybar"
    ["rofi"]="rofi"
    ["ffmpegthumbnailer"]="ffmpegthumbnailer"
    ["ffmpeg"]="ffmpeg"
    ["dunst"]="dunst"
    ["matugen"]="BUILD"  # Install via cargo
    ["foot"]="foot"
    ["swww"]="BUILD"  # Install via cargo
    ["swayidle"]="swayidle"
    ["hyprlock"]="BUILD"  # Not in repos
    ["qt5-wayland"]="qtwayland5"
    ["qt6-wayland"]="qt6-wayland"
    ["nm-connection-editor"]="network-manager-gnome"
    ["polkit-gnome"]="policykit-1-gnome"
    ["gnome-keyring"]="gnome-keyring"
    ["wf-recorder"]="wf-recorder"
    ["grim"]="grim"
    ["slurp"]="slurp"
    ["playerctl"]="playerctl"
    ["font-awesome"]="fonts-font-awesome"
    ["inter-font"]="fonts-inter"
    ["roboto-font"]="fonts-roboto"
    ["papirus-icon-theme"]="papirus-icon-theme"
    ["adw-gtk-theme"]="BUILD"  # Not in repos
)

# Get package list based on distribution
get_package_name() {
    local pkg_key="$1"
    if [ "$DISTRO_FAMILY" = "arch" ]; then
        echo "${arch_packages[$pkg_key]}"
    elif [ "$DISTRO_FAMILY" = "debian" ]; then
        echo "${debian_packages[$pkg_key]}"
    fi
}

# --- Dependency Checker Function ---
check_dependencies() {    
    echo -e "${blue}[DEPENDENCY CHECK]${nc} Checking installed packages..."
    sleep 0.5
    
    # Update package database
    echo -e "${yellow}Updating package database...${nc}"
    $UPDATE_CMD > /dev/null 2>&1
    
    missing_pkg=()
    build_required=false
    
    # Check each package
    for pkg_key in "${!arch_packages[@]}"; do
        pkg_name=$(get_package_name "$pkg_key")
        
        # Skip if package needs building (handle separately)
        if [ "$pkg_name" = "BUILD" ]; then
            build_required=true
            continue
        fi
        
        # Check if installed
        if [ "$DISTRO_FAMILY" = "arch" ]; then
            if ! pacman -Qi "$pkg_name" &> /dev/null; then
                missing_pkg+=("$pkg_name")
            fi
        elif [ "$DISTRO_FAMILY" = "debian" ]; then
            if ! dpkg -l "$pkg_name" 2>/dev/null | grep -q "^ii"; then
                missing_pkg+=("$pkg_name")
            fi
        fi
    done
    
    # Install missing packages
    if [ ${#missing_pkg[@]} -eq 0 ]; then
        echo -e "${green}All available packages are already installed!${nc}"
    else
        echo -e "${yellow}The following packages will be installed:${nc}"
        for pkg in "${missing_pkg[@]}"; do
            echo -e " - $pkg"
        done
        echo ""
        sleep 0.5
        echo -e "${blue}Starting installation...${nc}"
        sleep 0.5
        
        for pkg in "${missing_pkg[@]}"; do
            echo -e "Installing ${yellow}$pkg${nc}..."
            if $INSTALL_CMD "$pkg" > /dev/null 2>&1; then
                echo -e "${green}✓ Successfully installed $pkg${nc}"
            else
                echo -e "${red}✗ Failed to install $pkg${nc}"
            fi
        done
    fi
    
    # Handle packages that need building (Debian/Ubuntu only)
    if [ "$build_required" = true ] && [ "$DISTRO_FAMILY" = "debian" ]; then
        echo ""
        echo -e "${yellow}╔════════════════════════════════════════════════════════════╗${nc}"
        echo -e "${yellow}║  Some packages need to be built from source               ║${nc}"
        echo -e "${yellow}║  (labwc, matugen, hyprlock, swww, cliphist)               ║${nc}"
        echo -e "${yellow}║  This will take approximately 15-30 minutes               ║${nc}"
        echo -e "${yellow}╚════════════════════════════════════════════════════════════╝${nc}"
        echo ""
        read -p "Build required packages now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "$SCRIPT_DIR/build-deps-ubuntu.sh" ]; then
                bash "$SCRIPT_DIR/build-deps-ubuntu.sh"
            else
                echo -e "${red}Error: build-deps-ubuntu.sh not found!${nc}"
                echo -e "${yellow}Please build the following manually:${nc}"
                echo -e " - labwc, matugen, hyprlock, swww, cliphist"
            fi
        else
            echo -e "${yellow}Skipping build. You'll need to install these manually:${nc}"
            echo -e " - labwc, matugen, hyprlock, swww, cliphist"
        fi
    fi
    
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
fc-cache -fv > /dev/null 2>&1
echo -e "${green}Fonts installed and cache updated.${nc}"
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
echo -e "${blue}Note: If using rofi, navigate with Arrow Keys/Tab and press Enter to select${nc}"
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
swww-daemon > /dev/null 2>&1 &
echo -e "Started ${green}swww-daemon${nc}"
sleep 0.5
dunst > /dev/null 2>&1 &
echo -e "Started ${green}dunst${nc}"
sleep 0.5
waybar > /dev/null 2>&1 &
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
    > "$HOME/.config/labwc/idle/idle.log" 2>&1 &
}


# Check if labwc is running
if pgrep -x "labwc" > /dev/null; then
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


# this script will be sourced by other scripts

# file paths
CONFIG_HOME=$(eval echo "~${SUDO_USER:-$USER}") # this is used because dns script runs as root
waybar_config_dir="$CONFIG_HOME/.config/waybar"
style_file="$waybar_config_dir/style.css"

# --- COLOR EXTRACTION LOGIC ---

# 1. check for the currently used color css file in `style.css` of waybar
# 2. find the colors value from the currently used css file

# Default Fallbacks
primary_color="#a6e3a1"   # Matcha Green
secondary_color="#ff7a93" # Flamingo Pink

# Find the active color file from style.css
imported_file=$(sed -n 's/.*@import "colors\/\(.*\)";.*/\1/p' "$style_file" | head -n 1)

if [ -n "$imported_file" ]; then
    full_color_path="$waybar_config_dir/colors/$imported_file"
    if [ -f "$full_color_path" ]; then
        css_primary=$(grep "@define-color primary" "$full_color_path" | awk '{print $3}' | tr -d ';')
        css_secondary=$(grep "@define-color power" "$full_color_path" | awk '{print $3}' | tr -d ';')
        if [ -n "$css_primary" ]; then primary_color="$css_primary"; fi
        if [ -n "$css_secondary" ]; then secondary_color="$css_secondary"; fi
    fi
fi

# ansi formatting for terminal use
bold="\033[1m"
reset="\033[0m"
# helper to convert hex color to ansi rgb
hex_to_ansi() {
    local hex=$1
    if [[ "$hex" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        # Output the ANSI sequence
        printf "\033[38;2;%d;%d;%dm" 0x${hex:1:2} 0x${hex:3:2} 0x${hex:5:2}
    fi
}
term_primary=$(hex_to_ansi "$primary_color")
term_secondary=$(hex_to_ansi "$secondary_color")

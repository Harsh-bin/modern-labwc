#!/bin/bash

# Smart menu generator that detects the best dialog method
# Falls back to terminal prompts if rofi isn't available or not in a graphical environment

menu_generator="$HOME/.config/labwc/menu-generator.py"
menu_file="$HOME/.config/labwc/menu.xml"
horizontal_menu="$HOME/.config/rofi/horizontal_menu.rasi"
terminal_script="$HOME/.config/labwc/menu-generator-terminal.sh"

# --- Detection Functions ---

# Check if rofi is available
has_rofi() {
    command -v rofi &> /dev/null
}

# Check if we're in a graphical environment
has_display() {
    [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]
}

# Check if labwc is running
is_labwc_running() {
    pgrep -x "labwc" > /dev/null
}

# --- Choose Dialog Method ---

if has_rofi && has_display; then
    # Use rofi dialog
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  TIP: Use Arrow Keys or Tab to navigate, Enter to select  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    sleep 1
    
    main_options="Yes\nNo"
    main_choice=$(echo -e "$main_options" | rofi -dmenu -mesg "<b>Footer in menu?</b>" -theme "$horizontal_menu")
    
    # Handle the choice
    case "$main_choice" in
        "Yes")
            python3 "$menu_generator" -o "$menu_file"
            # Notify user about menu generated
            if command -v notify-send &> /dev/null; then
                notify-send "SUCCESS" "Desktop menu generated with Footer"
            fi
            echo "✓ Desktop menu generated with footer"
            ;;
        
        "No")
            python3 "$menu_generator" -f false -o "$menu_file"
            # Notify user about menu generated
            if command -v notify-send &> /dev/null; then
                notify-send "SUCCESS" "Desktop menu generated without Footer"
            fi
            echo "✓ Desktop menu generated without footer"
            ;;
        
        *)
            # User cancelled or no selection
            exit 0
            ;;
    esac
else
    # Fall back to terminal-based menu
    if [ -f "$terminal_script" ]; then
        bash "$terminal_script"
    else
        # Fallback if terminal script is missing
        echo ""
        echo "Rofi not available. Using terminal prompts."
        echo ""
        read -p "Include footer in menu? (y/n): " choice
        case "$choice" in
            y|Y|yes|Yes)
                python3 "$menu_generator" -o "$menu_file"
                echo "✓ Desktop menu generated with footer"
                ;;
            *)
                python3 "$menu_generator" -f false -o "$menu_file"
                echo "✓ Desktop menu generated without footer"
                ;;
        esac
    fi
fi

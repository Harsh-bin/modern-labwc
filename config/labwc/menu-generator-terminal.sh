#!/bin/bash

# Terminal-based menu generator (fallback for when rofi isn't available)
# This provides the same functionality as the rofi-based menu but uses simple terminal prompts

menu_generator="$HOME/.config/labwc/menu-generator.py"
menu_file="$HOME/.config/labwc/menu.xml"

echo ""
echo "========================================="
echo "  Labwc Desktop Menu Configuration"
echo "========================================="
echo ""
echo "Do you want to include a footer in the desktop menu?"
echo ""
echo "The footer displays system information at the bottom of the menu."
echo ""
echo "  1) Yes - Include footer with system info"
echo "  2) No  - Clean menu without footer"
echo ""
read -p "Enter your choice (1 or 2): " choice

case "$choice" in
    1|Yes|yes|Y|y)
        echo ""
        echo "Generating desktop menu with footer..."
        python3 "$menu_generator" -o "$menu_file"
        if [ $? -eq 0 ]; then
            echo "✓ Desktop menu generated with footer"
        else
            echo "✗ Failed to generate menu"
            exit 1
        fi
        ;;
    
    2|No|no|N|n)
        echo ""
        echo "Generating desktop menu without footer..."
        python3 "$menu_generator" -f false -o "$menu_file"
        if [ $? -eq 0 ]; then
            echo "✓ Desktop menu generated without footer"
        else
            echo "✗ Failed to generate menu"
            exit 1
        fi
        ;;
    
    *)
        echo ""
        echo "Invalid choice. Defaulting to menu without footer."
        python3 "$menu_generator" -f false -o "$menu_file"
        if [ $? -eq 0 ]; then
            echo "✓ Desktop menu generated without footer"
        else
            echo "✗ Failed to generate menu"
            exit 1
        fi
        ;;
esac

echo ""

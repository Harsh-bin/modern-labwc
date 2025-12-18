#!/bin/bash

#####################################
## author @Harsh-bin Github #########
#####################################

# Fade out/in screen brightness smoothly 

# Brightness cache file
cache_file="$HOME/.config/labwc/idle/brightness.cache"    
# Get the current brightness of screen
current_val=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
step=2 

# --- Function to control screen brightness ---
fade_out_screen() {
    if [ "$current_val" -eq "0" ]; then
        echo "Screen already at 0% brightness. No fade out needed."
        # saves the current value so faddding screen in doesn't crashes.
        echo "$current_val" > "$cache_file"
        return 0
    else
        # --- FADE OUT ---
        # saves the current value so it can be used later
        echo "$current_val" > "$cache_file"   
        # loop from current brightness to 0     
        echo "Fading OUT..."        
        for (( i=current_val; i>=0; i-=step )); do
            brightnessctl -q set "${i}%"
            sleep 0.01
        done
        # Ensure it hits exactly 0
        brightnessctl -q set 0%
    fi
}

fade_in_screen() {
    # --- FADE IN ---        
    # reads the stored value from cache file
    if [ -f "$cache_file" ]; then
        target_val=$(<"$cache_file")   
        if [ "$target_val" -eq "0" ]; then
            echo "Cached brightness is 0%. No fade in needed."
            return 0   
        else
            echo "Fading IN..."
            # loop from current brightness to target brightness
            for (( i=current_val; i<=target_val; i+=step )); do
            brightnessctl -q set "${i}%"
            sleep 0.01
        done
        # Ensure it hits the exact target
        brightnessctl -q set "${target_val}%"
        fi
    fi

}

case $1 in
    "--fade-out")
        fade_out_screen
        ;;
    "--fade-in")
        fade_in_screen
        ;;
    *)
        echo "Usage: $0 --fade-out or --fade-in"
        exit 0
        ;;
esac

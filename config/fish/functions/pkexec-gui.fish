function pkexec
    # Ensure WAYLAND_DISPLAY is set (it should be, by labwc/LightDM)
    if not set -q WAYLAND_DISPLAY
        echo "Error: WAYLAND_DISPLAY is not set. Are you in a Wayland session?"
        return 1
    end

    # Explicitly pass the necessary environment variables to the elevated process
    # The XDG_RUNTIME_DIR=/run/user/0 part is a common workaround/standard for pkexec environments
    pkexec env WAYLAND_DISPLAY="$WAYLAND_DISPLAY" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$argv"
end

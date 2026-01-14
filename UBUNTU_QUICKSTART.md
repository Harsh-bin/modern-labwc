# Ubuntu 24.04 Quick Start Guide

## Prerequisites

Before running the setup script, ensure you have:
- Ubuntu 24.04 (or compatible Debian-based system)
- Sudo privileges
- Internet connection
- At least 2GB free disk space (for building packages)

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/Harsh-bin/modern-labwc/
cd modern-labwc
```

### 2. Run the Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

### 3. What to Expect

The script will:

1. **Detect your distribution** (Ubuntu 24.04)
2. **Update package database**
3. **Install available packages** from Ubuntu repos (~5 minutes)
4. **Prompt to build missing packages** (labwc, matugen, hyprlock, swww, cliphist)
   - If you choose "Yes", it will take 15-30 minutes
   - The build process is fully automated
5. **Deploy configurations** to `~/.config/`
6. **Install fonts** to `~/.local/share/`
7. **Install GTK theme** to `~/.themes/`
8. **Configure wallpaper directory**
9. **Start background services** (if labwc is running)
10. **Launch wallpaper selector**
11. **Customize waybar**

## Build Process Details

When building packages, the script will:

### Install Build Dependencies
```
build-essential, meson, ninja-build, cmake, pkg-config
libwayland-dev, libwlroots-dev, libxkbcommon-dev
libcairo2-dev, libpango1.0-dev, and more...
```

### Install Rust (for matugen and swww)
```
Rust toolchain via rustup
```

### Build Packages
1. **labwc** - Wayland compositor (5-10 min)
2. **matugen** - Color generator via cargo (3-5 min)
3. **hyprlock** - Screen locker (3-5 min)
4. **swww** - Wallpaper daemon via cargo (3-5 min)
5. **cliphist** - Clipboard manager (1-2 min)

Build logs are saved to: `~/.cache/modern-labwc-build/build.log`

## Post-Installation

### Starting Labwc

1. **Log out** of your current session
2. At the login screen, select **labwc** from the session menu
3. Log in

### First Launch

On first login, you'll be prompted to:
1. Select a wallpaper (generates color scheme)
2. Choose waybar position (top/bottom)
3. Choose waybar style (pill/square/outline/etc.)

### Key Bindings

- `Super + Return` - Open terminal
- `Super + 1-4` - Switch workspaces
- `Super + L` - Lock screen
- `Super + S` - Screenshot tool
- `Right-click desktop` - App menu

## Troubleshooting

### Rofi Dialog Not Responding

If you see a dialog asking "Footer in menu?" but clicking doesn't work:

**Solution 1: Use Keyboard Navigation**
- Rofi dialogs are keyboard-driven, not mouse-clickable
- Press **Arrow Keys** (← →) or **Tab** to highlight your choice
- Press **Enter** to select
- Press **Escape** to cancel

**Solution 2: Terminal Fallback**
- The setup script automatically detects if rofi isn't working
- If rofi fails, it will fall back to simple terminal prompts
- Just type `1` or `2` and press Enter

**Solution 3: Manual Menu Generation**
```bash
# Generate menu WITH footer:
python3 ~/.config/labwc/menu-generator.py -o ~/.config/labwc/menu.xml

# Generate menu WITHOUT footer:
python3 ~/.config/labwc/menu-generator.py -f false -o ~/.config/labwc/menu.xml
```

### Build Fails

If a package fails to build:

1. **Check the build log:**
   ```bash
   cat ~/.cache/modern-labwc-build/build.log
   ```

2. **Install missing dependencies manually:**
   ```bash
   sudo apt-get install <missing-package>
   ```

3. **Re-run the build script:**
   ```bash
   ./build-deps-ubuntu.sh
   ```

### Labwc Won't Start

1. **Check if labwc is installed:**
   ```bash
   which labwc
   ```

2. **If not found, build it manually:**
   ```bash
   cd ~/.cache/modern-labwc-build/labwc
   meson setup build
   ninja -C build
   sudo ninja -C build install
   ```

### Matugen Not Working

1. **Ensure Rust is in PATH:**
   ```bash
   source ~/.cargo/env
   ```

2. **Reinstall matugen:**
   ```bash
   cargo install matugen
   ```

### Theme Not Applying

1. **Regenerate theme:**
   ```bash
   ~/.config/rofi/wallselect/wallselect.sh
   ```

2. **Reload labwc:**
   ```bash
   Super + C  # or run: labwc --reconfigure
   ```

## Manual Build (Alternative)

If you prefer to build packages manually:

### 1. Install Build Dependencies
```bash
sudo apt-get update
sudo apt-get install build-essential meson ninja-build cmake pkg-config \
  libwayland-dev wayland-protocols libwlroots-dev libxkbcommon-dev \
  libcairo2-dev libpango1.0-dev libglib2.0-dev libpixman-1-dev \
  libinput-dev libxml2-dev libdrm-dev libjson-c-dev libseat-dev \
  scdoc git curl wget golang-go
```

### 2. Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### 3. Build labwc
```bash
git clone https://github.com/labwc/labwc.git
cd labwc
meson setup build
ninja -C build
sudo ninja -C build install
```

### 4. Install matugen
```bash
cargo install matugen
```

### 5. Build hyprlock
```bash
sudo apt-get install libpam0g-dev libmagic-dev
git clone https://github.com/hyprwm/hyprlock.git
cd hyprlock
cmake -B build
cmake --build build
sudo cmake --install build
```

### 6. Install swww
```bash
cargo install swww
```

### 7. Build cliphist
```bash
git clone https://github.com/sentriz/cliphist.git
cd cliphist
go build
sudo install -Dm755 cliphist /usr/local/bin/cliphist
```

## Getting Help

- Check the main [README.md](../Readme.md) for feature documentation
- Review build logs in `~/.cache/modern-labwc-build/build.log`
- Check labwc logs: `~/.config/labwc/idle/idle.log`

## Next Steps

After successful installation:
1. Explore the 20 pre-configured themes
2. Try different Rofi launchers and powermenus
3. Customize waybar styles
4. Set up your wallpaper collection
5. Enjoy your beautiful Wayland desktop! 🎉

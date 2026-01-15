#!/bin/bash

# Build Dependencies for Ubuntu/Debian
# This script builds packages not available in Ubuntu repositories

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m'

# Build directory
BUILD_DIR="$HOME/.cache/modern-labwc-build"
mkdir -p "$BUILD_DIR"

# Log file
LOG_FILE="$BUILD_DIR/build.log"
echo "Build started at $(date)" > "$LOG_FILE"

# Function to log messages
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if package is installed
is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

echo -e "${blue}╔════════════════════════════════════════════════════════════╗${nc}"
echo -e "${blue}║  Modern Labwc - Ubuntu/Debian Build Dependencies Script  ║${nc}"
echo -e "${blue}╚════════════════════════════════════════════════════════════╝${nc}"
echo ""

# Install build dependencies
install_build_deps() {
    echo -e "${yellow}[1/7] Installing build dependencies...${nc}"
    
    BUILD_DEPS=(
        # Build tools
        "build-essential"
        "meson"
        "ninja-build"
        "cmake"
        "pkg-config"
        "git"
        "curl"
        "wget"
        
        # labwc dependencies
        "libwayland-dev"
        "wayland-protocols"
        "libwlroots-dev"
        "libxkbcommon-dev"
        "libcairo2-dev"
        "libpango1.0-dev"
        "libglib2.0-dev"
        "libpixman-1-dev"
        "libinput-dev"
        "libxml2-dev"
        "libdrm-dev"
        "libjson-c-dev"
        "libseat-dev"
        "scdoc"
        
        # hyprlock dependencies
        "libpam0g-dev"
        "libmagic-dev"
        "libhyprlang-dev"
    )
    
    sudo apt-get update
    for dep in "${BUILD_DEPS[@]}"; do
        if ! is_installed "$dep"; then
            log "Installing $dep..."
            sudo apt-get install -y "$dep" >> "$LOG_FILE" 2>&1
        fi
    done
    
    echo -e "${green}✓ Build dependencies installed${nc}"
}

# Install Rust and Cargo for swww
install_rust() {
    echo -e "${yellow}[2/7] Checking Rust installation...${nc}"
    
    if command_exists cargo; then
        echo -e "${green}✓ Rust/Cargo already installed${nc}"
    else
        log "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1
        source "$HOME/.cargo/env"
        echo -e "${green}✓ Rust installed${nc}"
    fi
}

# Build labwc
build_labwc() {
    echo -e "${yellow}[3/7] Building labwc...${nc}"
    
    if command_exists labwc; then
        echo -e "${green}✓ labwc already installed${nc}"
        return
    fi
    
    # Check if running on Ubuntu to use PPA
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            log "Detected Ubuntu system. Installing labwc from PPA..."
            echo -e "${yellow}Adding labwc PPA...${nc}"
            sudo add-apt-repository -y ppa:labwc-contributors/labwc >> "$LOG_FILE" 2>&1
            sudo apt-get update >> "$LOG_FILE" 2>&1
            sudo apt-get install -y labwc >> "$LOG_FILE" 2>&1
            
            echo -e "${green}✓ labwc installed via PPA${nc}"
            return
        fi
    fi

    # Fallback to building from source (Debian / others)
    log "Building labwc from source (Debian/Other)..."
    cd "$BUILD_DIR"
    log "Cloning labwc repository..."
    git clone https://github.com/labwc/labwc.git >> "$LOG_FILE" 2>&1
    cd labwc
    
    log "Building labwc with meson..."
    meson setup build >> "$LOG_FILE" 2>&1
    ninja -C build >> "$LOG_FILE" 2>&1
    sudo ninja -C build install >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ labwc built and installed${nc}"
}

# Install matugen binary from GitHub releases
install_matugen() {
    echo -e "${yellow}[4/7] Installing matugen...${nc}"
    
    if command_exists matugen; then
        echo -e "${green}✓ matugen already installed${nc}"
        return
    fi
    
    log "Downloading matugen binary from GitHub releases..."
    MATUGEN_VERSION=$(curl -s https://api.github.com/repos/InioX/matugen/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    MATUGEN_URL="https://github.com/InioX/matugen/releases/download/v${MATUGEN_VERSION}/matugen-linux-x86_64"
    
    curl -L "$MATUGEN_URL" -o "$BUILD_DIR/matugen" >> "$LOG_FILE" 2>&1
    chmod +x "$BUILD_DIR/matugen"
    sudo mv "$BUILD_DIR/matugen" /usr/local/bin/matugen
    
    echo -e "${green}✓ matugen installed${nc}"
}

# Build hyprlock
build_hyprlock() {
    echo -e "${yellow}[5/7] Building hyprlock...${nc}"
    
    if command_exists hyprlock; then
        echo -e "${green}✓ hyprlock already installed${nc}"
        return
    fi
    
    cd "$BUILD_DIR"
    log "Cloning hyprlock repository..."
    git clone https://github.com/hyprwm/hyprlock.git >> "$LOG_FILE" 2>&1
    cd hyprlock
    
    log "Building hyprlock with cmake..."
    cmake -B build >> "$LOG_FILE" 2>&1
    cmake --build build >> "$LOG_FILE" 2>&1
    sudo cmake --install build >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ hyprlock built and installed${nc}"
}

# Build swww
# Build swww
build_swww() {
    echo -e "${yellow}[6/7] Building swww...${nc}"
    
    if command_exists swww; then
        echo -e "${green}✓ swww already installed${nc}"
        return
    fi
    
    # Install dependencies for swww
    sudo apt-get install -y liblz4-dev >> "$LOG_FILE" 2>&1

    source "$HOME/.cargo/env"
    
    cd "$BUILD_DIR"
    log "Cloning swww repository..."
    git clone https://github.com/LGFae/swww.git >> "$LOG_FILE" 2>&1
    cd swww
    
    log "Building swww..."
    cargo build --release >> "$LOG_FILE" 2>&1
    
    # Install binaries
    sudo cp target/release/swww /usr/local/bin/
    sudo cp target/release/swww-daemon /usr/local/bin/
    
    echo -e "${green}✓ swww installed${nc}"
}

# Build cliphist
# Install cliphist binary from GitHub releases
install_cliphist() {
    echo -e "${yellow}[7/7] Installing cliphist...${nc}"
    
    if command_exists cliphist; then
        echo -e "${green}✓ cliphist already installed${nc}"
        return
    fi
    
    log "Downloading cliphist binary from GitHub releases..."
    CLIPHIST_URL="https://github.com/sentriz/cliphist/releases/download/v0.7.0/v0.7.0-linux-amd64"
    
    curl -L "$CLIPHIST_URL" -o "$BUILD_DIR/cliphist" >> "$LOG_FILE" 2>&1
    chmod +x "$BUILD_DIR/cliphist"
    sudo mv "$BUILD_DIR/cliphist" /usr/local/bin/cliphist
    
    echo -e "${green}✓ cliphist installed${nc}"
}

# Install adw-gtk3 theme from GitHub releases
install_adw_gtk3() {
    echo -e "${yellow}[8/8] Installing adw-gtk3 theme...${nc}"
    
    THEME_DIR="$HOME/.local/share/themes"
    mkdir -p "$THEME_DIR"
    
    if [ -d "$THEME_DIR/adw-gtk3" ] && [ -d "$THEME_DIR/adw-gtk3-dark" ]; then
        echo -e "${green}✓ adw-gtk3 theme already installed${nc}"
        return
    fi
    
    log "Downloading adw-gtk3 theme from GitHub releases..."
    ADW_VERSION=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    ADW_URL="https://github.com/lassekongo83/adw-gtk3/releases/download/v${ADW_VERSION}/adw-gtk3v${ADW_VERSION}.tar.xz"
    
    curl -L "$ADW_URL" -o "$BUILD_DIR/adw-gtk3.tar.xz" >> "$LOG_FILE" 2>&1
    
    log "Extracting adw-gtk3 theme..."
    tar -xf "$BUILD_DIR/adw-gtk3.tar.xz" -C "$THEME_DIR" >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ adw-gtk3 theme installed${nc}"
}

# Main execution
main() {
    echo -e "${blue}This will build and install packages not available in Ubuntu repositories.${nc}"
    echo -e "${blue}Estimated time: 15-30 minutes depending on your system.${nc}"
    echo ""
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${red}Build cancelled.${nc}"
        exit 1
    fi
    
    install_build_deps
    install_rust
    build_labwc
    install_matugen
    build_hyprlock
    build_swww
    install_cliphist
    install_adw_gtk3
    
    echo ""
    echo -e "${green}╔════════════════════════════════════════════════════════════╗${nc}"
    echo -e "${green}║            All packages built successfully!                ║${nc}"
    echo -e "${green}╚════════════════════════════════════════════════════════════╝${nc}"
    echo ""
    echo -e "${blue}Build log saved to: ${yellow}$LOG_FILE${nc}"
    echo -e "${blue}You may need to run: ${yellow}source ~/.cargo/env${nc}"
    echo ""
}

main "$@"

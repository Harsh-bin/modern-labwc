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
        "build-essential"
        "meson"
        "ninja-build"
        "cmake"
        "pkg-config"
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
        "git"
        "curl"
        "wget"
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

# Install Rust and Cargo for matugen
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

# Install matugen via cargo
install_matugen() {
    echo -e "${yellow}[4/7] Installing matugen...${nc}"
    
    if command_exists matugen; then
        echo -e "${green}✓ matugen already installed${nc}"
        return
    fi
    
    source "$HOME/.cargo/env"
    log "Installing matugen via cargo..."
    cargo install matugen >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ matugen installed${nc}"
}

# Build hyprlock
build_hyprlock() {
    echo -e "${yellow}[5/7] Building hyprlock...${nc}"
    
    if command_exists hyprlock; then
        echo -e "${green}✓ hyprlock already installed${nc}"
        return
    fi
    
    # Install additional dependencies for hyprlock
    sudo apt-get install -y libpam0g-dev libmagic-dev libhyprlang-dev >> "$LOG_FILE" 2>&1
    
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
build_swww() {
    echo -e "${yellow}[6/7] Building swww...${nc}"
    
    if command_exists swww; then
        echo -e "${green}✓ swww already installed${nc}"
        return
    fi
    
    source "$HOME/.cargo/env"
    log "Installing swww via cargo..."
    cargo install swww >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ swww installed${nc}"
}

# Build cliphist
build_cliphist() {
    echo -e "${yellow}[7/7] Building cliphist...${nc}"
    
    if command_exists cliphist; then
        echo -e "${green}✓ cliphist already installed${nc}"
        return
    fi
    
    # Install Go if needed
    if ! command_exists go; then
        log "Installing Go..."
        sudo apt-get install -y golang-go >> "$LOG_FILE" 2>&1
    fi
    
    cd "$BUILD_DIR"
    log "Cloning cliphist repository..."
    git clone https://github.com/sentriz/cliphist.git >> "$LOG_FILE" 2>&1
    cd cliphist
    
    log "Building cliphist..."
    go build >> "$LOG_FILE" 2>&1
    sudo install -Dm755 cliphist /usr/local/bin/cliphist >> "$LOG_FILE" 2>&1
    
    echo -e "${green}✓ cliphist built and installed${nc}"
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
    build_cliphist
    
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

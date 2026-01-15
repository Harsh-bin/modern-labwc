#!/bin/bash

# Distribution Detection Script for Modern Labwc
# Detects the Linux distribution and exports package manager commands

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m' # No Color

# Detect distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_ID_LIKE="$ID_LIKE"
        DISTRO_NAME="$NAME"
        DISTRO_VERSION="$VERSION_ID"
    else
        echo -e "${red}Error: Cannot detect distribution. /etc/os-release not found.${nc}"
        exit 1
    fi
}

# Determine package manager and distro family
determine_package_manager() {
    case "$DISTRO_ID" in
        arch|manjaro|endeavouros|garuda)
            DISTRO_FAMILY="arch"
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm --needed"
            CHECK_CMD="pacman -Qi"
            UPDATE_CMD="sudo pacman -Sy"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            DISTRO_FAMILY="debian"
            PKG_MANAGER="apt"
            INSTALL_CMD="sudo apt-get install -y"
            CHECK_CMD="dpkg -l"
            UPDATE_CMD="sudo apt-get update"
            ;;

        *)
            # Check ID_LIKE for derivative distributions
            if [[ "$DISTRO_ID_LIKE" == *"arch"* ]]; then
                DISTRO_FAMILY="arch"
                PKG_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm --needed"
                CHECK_CMD="pacman -Qi"
                UPDATE_CMD="sudo pacman -Sy"
            elif [[ "$DISTRO_ID_LIKE" == *"debian"* ]] || [[ "$DISTRO_ID_LIKE" == *"ubuntu"* ]]; then
                DISTRO_FAMILY="debian"
                PKG_MANAGER="apt"
                INSTALL_CMD="sudo apt-get install -y"
                CHECK_CMD="dpkg -l"
                UPDATE_CMD="sudo apt-get update"
            else
                echo -e "${red}Error: Unsupported distribution: $DISTRO_ID${nc}"
                echo -e "${yellow}Supported distributions: Arch, Ubuntu, Debian and their derivatives${nc}"
                exit 1
            fi
            ;;
    esac
}

# Export variables for use in other scripts
export_variables() {
    export DISTRO_ID
    export DISTRO_NAME
    export DISTRO_VERSION
    export DISTRO_FAMILY
    export PKG_MANAGER
    export INSTALL_CMD
    export CHECK_CMD
    export UPDATE_CMD
}

# Main execution
main() {
    detect_distribution
    determine_package_manager
    export_variables
    
    # Print detection results if run directly
    if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
        echo -e "${blue}=== Distribution Detection ===${nc}"
        echo -e "Distribution: ${green}$DISTRO_NAME${nc}"
        echo -e "ID: ${green}$DISTRO_ID${nc}"
        echo -e "Version: ${green}$DISTRO_VERSION${nc}"
        echo -e "Family: ${green}$DISTRO_FAMILY${nc}"
        echo -e "Package Manager: ${green}$PKG_MANAGER${nc}"
        echo ""
    fi
}

main "$@"

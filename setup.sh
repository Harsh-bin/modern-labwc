#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m' # Sin color

comp="$HOME/compilados"
bin_path="$HOME/.local/bin"
source="./config"
dest="$HOME/.config"
font_source="./fonts.tar.xz"
font_dest="$HOME/.local/share"
cursor_source="./Bibata-Modern-Ice.tar.xz"
cursor_dest="$HOME/.local/share/icons"
theme_source="./themes.tar.xz"
theme_dest="$HOME/.themes"
adw_url="https://github.com/lassekongo83/adw-gtk3/releases/download/v6.5/adw-gtk3v6.5.tar.xz"
awww_url="https://codeberg.org/LGFae/awww.git"

timestamp=$(date +%Y%m%d-%H%M%S)
backup_root="$HOME/.config/BACKUP"
backup_dir="$backup_root/$timestamp"

# dependencias probadas en Debian testing(futura Debian 14) y Ubuntu (en particular Xubuntu)
dependencies=(
    # Compositor y Gestor de Ventanas
    "labwc"
    "waybar"
    "rofi-dev"
    "rofi"
    "foot"
    "dunst"
    "swayidle"
    "hyprlock"

    # Portales XDG y Autenticación Polkit
    "xdg-desktop-portal"
    "xdg-desktop-portal-wlr"
    "lxqt-policykit"
    "gnome-keyring"

    # Portapapeles y Automatización de Entrada
    "wl-clipboard"
    "cliphist"
    "nwg-clipman"
    "wtype"

    # Integración con Aplicaciones Qt5 y Qt6
    "qtwayland5"
    "qt5ct"
    "qt6ct"
    "qt6-wayland"

    # Multimedia, Audio y Brillo
    "ffmpeg"
    "ffmpegthumbnailer"
    "mpv"
    "mpv-mpris"
    "playerctl"
    "pavucontrol"
    "pamixer"
    "brightnessctl"
    "alsa-utils"

    # Captura de Pantalla y Herramientas Gráficas
    "grim"
    "slurp"
    "wf-recorder"
    "feh"
    "imagemagick"

    # Utilidades de Sistema, Red y Scripts
    "gammastep"
    "network-manager-applet"
    "thunar"
    "xfce4-taskmanager"
    "jq"
    "curl"
    "yt-dlp"
    "socat"
    "netcat-openbsd"
    "python3-watchdog"

    # Fuentes Tipográficas y Temas
    "fonts-font-awesome"
    "fonts-inter"
    "fonts-roboto"
    "papirus-icon-theme"

    # Para compilar awww
    "liblz4-dev"
    "lz4"
    "git"
    "build-essential"
    "pkg-config"
    "libwayland-dev"
    "wayland-protocols"
    "scdoc"
)

# Herramientas complementarias (fuera de repositorios base o compiladas con Cargo)
external_tools=("matugen" "wl-clip-persist")

# Verificación e Instalación de Dependencias ---
check_dependencies() {
    echo -e "${blue}[DEPENDENCY CHECK]${nc} Actualizando repositorios locales..."
    #    sudo apt-get update -y

    echo -e "${blue}[DEPENDENCY CHECK]${nc} Comprobando estado de paquetes instalados..."
    missing_pkg=()
    for pkg in "${dependencies[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkg+=("$pkg")
        fi
    done

    if [ ${#missing_pkg[@]} -eq 0 ]; then
        echo -e "${green}Todas las dependencias de APT ya están instaladas.${nc}"
    else
        echo -e "${yellow}Se detectaron paquetes faltantes:${nc}"
        for pkg in "${missing_pkg[@]}"; do
            echo -e " - $pkg"
        done

        echo -e "\n${blue}Iniciando instalación de paquetes faltantes...${nc}"
        for pkg in "${missing_pkg[@]}"; do
            echo -e "Instalando ${yellow}$pkg${nc}..."
            if sudo apt-get install -y "$pkg"; then
                echo -e "${green}Instalado correctamente: $pkg${nc}"
            else
                echo -e "${red}Error al instalar: $pkg (verifica disponibilidad en repos).${nc}"
            fi
            sleep 0.2
        done
    fi

    # Comprobación de herramientas externas en PATH
    echo -e "\n${blue}[EXTERNAL TOOLS CHECK]${nc} Comprobando herramientas complementarias en \$PATH..."
    for tool in "${external_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo -e " - $tool: ${green}Presente (${nc}$(command -v "$tool")${green})${nc}"
        else
            echo -e " - $tool: ${yellow}No encontrado.${nc} (Instalar opcionalmente vía Cargo o GitHub Release)."
        fi
    done
    echo "-------------------------------------------------"
}

# Función: Respaldo de Configuraciones Previas ---
backup_existing_configs() {
    if [ ! -d "$source" ]; then
        return
    fi

    echo -e "${yellow}Comprobando si existen configuraciones previas para respaldar...${nc}"
    dirs_to_backup=()
    for folder_path in "$source"/*; do
        folder_name=$(basename "$folder_path")
        if [ -d "$dest/$folder_name" ]; then
            dirs_to_backup+=("$folder_name")
        fi
    done

    if [ ${#dirs_to_backup[@]} -gt 0 ]; then
        echo -e "${blue}Creando respaldo en:${nc} ${yellow}$backup_dir${nc}"
        mkdir -p "$backup_dir"
        for folder_name in "${dirs_to_backup[@]}"; do
            echo -e "Moviendo a respaldo: ${yellow}$folder_name${nc}..."
            mv "$dest/$folder_name" "$backup_dir/"
        done
        echo -e "${green}Respaldo finalizado con éxito.${nc}"
    else
        echo -e "${green}No se requirió respaldo (no hay conflictos previos).${nc}"
    fi
    echo "-------------------------------------------------"
}

# Función: Despliegue de Archivos de Configuración ---
install_configs() {
    if [ -d "$source" ]; then
        mkdir -p "$dest"
        echo -e "${yellow}Asignando permisos ejecutables (+x) a scripts en '$source'...${nc}"
        find "$source" -name "*.sh" -type f -exec chmod +x {} +

        echo -e "${yellow}Copiando configuraciones hacia $dest...${nc}"
        cp -r "$source"/* "$dest/"
        echo -e "${green}Archivos de configuración copiados.${nc}"
    fi
    echo "-------------------------------------------------"
}

# Función: Descargar adw-gtk3 y compilar awww
adw_awww() {
    # ADW-GTK3 desde github
    if [[ ! -d "$theme_dest" ]]; then
        mkdir -vp "$theme_dest"
    fi
    curl -L "$adw_url" | tar -xJ -C "$theme_dest"

    # COMPILAR AWWW
    mkdir "$comp"
    cd "$comp" || return
    git clone --depth=1 "$awww_url"
    cd awww || return
    cargo build --release

    cp -v target/release/awww target/release/awww-daemon "$bin_path"

    sudo cp -v completions/bash/awww.bash /etc/bash_completion.d/

    ./doc/gen.sh

    if [[ ! -d "$HOME/.local/share/man" ]]; then
        mkdir -vp "$HOME/.local/share/man"
    fi
    cp -v doc/generated/awww*.1 "$HOME/.local/share/man"
}

# Función: Instalación de Recursos Gráficos (Fuentes, Cursores, Temas) ---
install_assets() {
    # Fuentes
    if [ -f "$font_source" ]; then
        mkdir -p "$font_dest"
        echo -e "Extrayendo fuentes a ${yellow}$font_dest${nc}..."
        tar -xJf "$font_source" -C "$font_dest"
        fc-cache -fv >/dev/null 2>&1
        echo -e "${green}Fuentes instaladas y caché actualizado.${nc}"
    fi

    # Cursores
    if [ -f "$cursor_source" ]; then
        mkdir -p "$cursor_dest"
        echo -e "Extrayendo tema de cursores a ${yellow}$cursor_dest${nc}..."
        tar -xJf "$cursor_source" -C "$cursor_dest"
        echo -e "${green}Cursores instalados.${nc}"
    fi

    # Temas de Labwc
    if [ -f "$theme_source" ]; then
        mkdir -p "$theme_dest"
        echo -e "Extrayendo temas a ${yellow}$theme_dest${nc}..."
        tar -xJf "$theme_source" -C "$theme_dest"
        echo -e "${green}Temas de Labwc instalados.${nc}"
    fi
    echo "-------------------------------------------------"
}

# --- Función: Asignación de Grupos de Usuario ---
configure_user_groups() {
    local user
    user=$(whoami)
    echo -e "${blue}Verificando grupos del sistema para el usuario $user...${nc}"
    for grp in "input" "video"; do
        if getent group "$grp" >/dev/null 2>&1; then
            sudo usermod -aG "$grp" "$user"
            echo -e "${green}Usuario $user agregado al grupo '$grp'.${nc}"
        fi
    done
    echo "-------------------------------------------------"
}

# Función: Inicio de Servicios de Segundo Plano ---
start_background_services() {
    echo -e "${yellow}Iniciando servicios de segundo plano...${nc}"
    killall -q -w awww-daemon dunst waybar 2>/dev/null

    if command -v awww-daemon &>/dev/null; then
        awww-daemon >/dev/null 2>&1 &
        echo -e "Iniciado: ${green}awww-daemon${nc}"
    fi

    if command -v dunst &>/dev/null; then
        dunst >/dev/null 2>&1 &
        echo -e "Iniciado: ${green}dunst${nc}"
    fi

    if command -v waybar &>/dev/null; then
        waybar >/dev/null 2>&1 &
        echo -e "Iniciado: ${green}waybar${nc}"
    fi

    if [ -f "$HOME/.config/labwc/device-monitor.sh" ]; then
        bash "$HOME/.config/labwc/device-monitor.sh" >/dev/null 2>&1 &
        echo -e "Iniciado: ${green}device-monitor${nc}"
    fi

    if command -v swayidle &>/dev/null; then
        mkdir -p "$HOME/.config/labwc/idle"
        swayidle -w \
            timeout 300 "$HOME/.config/labwc/idle/brightness_ctrl.sh --fade-out" \
            resume "$HOME/.config/labwc/idle/brightness_ctrl.sh --fade-in" \
            timeout 600 "loginctl lock-session" \
            timeout 1800 "systemctl suspend" \
            lock "$HOME/.config/labwc/idle/lock_ctrl.sh" \
            before-sleep "$HOME/.config/labwc/idle/sleep_ctrl.sh" \
            after-resume "$HOME/.config/labwc/idle/brightness_ctrl.sh --fade-in" \
            >"$HOME/.config/labwc/idle/idle.log" 2>&1 &
        echo -e "Iniciado: ${green}swayidle con Hyprlock/control de brillo${nc}"
    fi
}

# FLUJO PRINCIPAL ---

check_dependencies
backup_existing_configs
install_configs
install_assets
configure_user_groups
adw_awww

echo -e "${blue}[POST-INSTALACIÓN Y CONFIGURACIÓN]${nc}"

# Configuración interactiva de wallpapers
read -r -p "Directorio de fondos de pantalla [$HOME/.local/share/backgrounds/]: " user_wall_path
wall_script="$HOME/.config/rofi/wallselect/wallselect.sh"
final_wall_path="${user_wall_path:-/usr/share/backgrounds/}"
final_wall_path="${final_wall_path%/}/"

if [ -f "$wall_script" ]; then
    sed -i "8s|.*|wall_dir=\"$final_wall_path\"|" "$wall_script"
    echo -e "${green}Ruta asignada en $wall_script: $final_wall_path${nc}"
fi

# Aplicar tema GTK si existe el script de soporte
if [ -f "$HOME/.config/labwc/gtk.sh" ]; then
    echo -e "${yellow}Aplicando tema GTK...${nc}"
    bash "$HOME/.config/labwc/gtk.sh"
fi

# Generación del menú dinámico de Labwc
if [ -f "$HOME/.config/labwc/menu-generator.sh" ]; then
    echo -e "${yellow}Generando menú de escritorio para Labwc...${nc}"
    bash "$HOME/.config/labwc/menu-generator.sh"
fi

# Gestión de servicios activos si la sesión ya está en ejecución
if pgrep -x "labwc" >/dev/null; then
    echo -e "${green}Sesión activa de Labwc detectada. Levantando servicios...${nc}"
    start_background_services
else
    echo -e "${green}Instalación finalizada. Inicia sesión en Labwc para activar el entorno.${nc}"
fi

echo "-------------------------------------------------"
echo -e "${green}¡Proceso completado exitosamente!${nc}"
exit 0

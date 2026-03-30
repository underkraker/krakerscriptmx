#!/bin/bash
# KRAKER MASTER - Quick Installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/username/repo/main/install.sh)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# 📊 Función de Barra de Carga
show_progress() {
    local duration=$1
    local message=$2
    local percent=$3
    local bar_size=20
    local filled_size=$(( percent * bar_size / 100 ))
    local empty_size=$(( bar_size - filled_size ))
    
    printf "\r  ${CYAN}[${NC}"
    printf "%${filled_size}s" | tr ' ' '#'
    printf "%${empty_size}s" | tr ' ' ' '
    printf "${CYAN}]${NC} ${percent}%% - ${YELLOW}${message}${NC}"
}

# 🛠️ Entorno No Interactivo
export DEBIAN_FRONTEND=noninteractive

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}    🐲 INSTALADOR KRAKER MASTER PANEL v2.0 🐲${NC}"
echo -e "${CYAN}======================================================${NC}"

# Check Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: Ejecuta este script como ROOT.${NC}"
   exit 1
fi

# 🚀 INICIO DE PROCESO
show_progress 1 "Inicializando sistema..." 10
sleep 1

# 🛡️ MÓDULO DE VERIFICACIÓN (Bypass si ya existe)
show_progress 1 "Validando Seguridad..." 25
if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    apt-get update -y > /dev/null 2>&1
    apt-get install -y curl jq wget git > /dev/null 2>&1
fi

TEMP_SHIELD="/tmp/KRAKER_Shield.sh"
wget -qO "$TEMP_SHIELD" "https://raw.githubusercontent.com/underkraker/krakerscriptmx/main/scripts/KRAKER_Shield.sh"
source "$TEMP_SHIELD"
show_progress 1 "Autenticando Key..." 45
verify_license || { echo -e "\n${RED}[!] Error en la verificación.${NC}"; exit 1; }

# Install Dependencies
show_progress 1 "Instalando Componentes..." 65
apt-get install -y ufw lsof openssl net-tools screen > /dev/null 2>&1

# Clone Repository
show_progress 1 "Descargando Panel..." 85
REPO_DIR="/root/kraker_master"
[[ -d "$REPO_DIR" ]] && rm -rf "$REPO_DIR"
git clone https://github.com/underkraker/krakerscriptmx.git "$REPO_DIR" > /dev/null 2>&1

# Set Permissions
show_progress 1 "Configurando Scripts..." 95
chmod +x "$REPO_DIR/menu.sh"
chmod +x "$REPO_DIR/scripts"/*.sh
ln -sf "$REPO_DIR/menu.sh" /usr/bin/kraker
ln -sf "$REPO_DIR/menu.sh" /usr/bin/menu
chmod +x /usr/bin/kraker /usr/bin/menu

# 🏁 FIN
show_progress 1 "¡LISTO!" 100
echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}✔ INSTALACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo -e "${YELLOW}Escribe 'kraker' o 'menu' para abrir el panel.${NC}"
echo -e "${CYAN}======================================================${NC}"

sleep 1
kraker

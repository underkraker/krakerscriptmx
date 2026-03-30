#!/bin/bash
# KRAKER MASTER - Quick Installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/username/repo/main/install.sh)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}    🐲 INSTALADOR KRAKER MASTER PANEL v2.0 🐲${NC}"
echo -e "${CYAN}======================================================${NC}"

# Check Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: Ejecuta este script como ROOT.${NC}"
   exit 1
fi

# 🛡️ MÓDULO DE VERIFICACIÓN MAESTRA (KRAKER SHIELD)
# Descargar escudo temporal para validar antes de clonar todo el repo
echo -e "${YELLOW}[*] Validando entorno de seguridad...${NC}"
apt update -y > /dev/null 2>&1
apt install -y curl jq wget git > /dev/null 2>&1
TEMP_SHIELD="/tmp/KRAKER_Shield.sh"
wget -qO "$TEMP_SHIELD" "https://raw.githubusercontent.com/underkraker/krakerscriptmx/main/scripts/KRAKER_Shield.sh"
source "$TEMP_SHIELD"
verify_license

# Install Dependencies (Essential Pack)
echo -e "${YELLOW}[*] Verificando dependencias críticas (Git, Curl, JQ, Wget)...${NC}"
# apt update -y > /dev/null 2>&1 # Ya hecho arriba
apt install -y ufw lsof openssl net-tools screen > /dev/null 2>&1

# Clone Repository
echo -e "${YELLOW}[*] Descargando Panel...${NC}"
REPO_DIR="/root/kraker_master"
if [[ -d "$REPO_DIR" ]]; then
    rm -rf "$REPO_DIR"
fi
git clone https://github.com/underkraker/krakerscriptmx.git "$REPO_DIR" > /dev/null 2>&1

# Set Permissions
echo -e "${YELLOW}[*] Configurando permisos y Banner Global...${NC}"
chmod +x "$REPO_DIR/menu.sh"
chmod +x "$REPO_DIR/scripts"/*.sh
source "$REPO_DIR/scripts/utils.sh"
setup_motd

# Create Shortcuts
echo -e "${YELLOW}[*] Creando accesos directos 'kraker' y 'menu'...${NC}"
ln -sf "$REPO_DIR/menu.sh" /usr/bin/kraker
ln -sf "$REPO_DIR/menu.sh" /usr/bin/menu
chmod +x /usr/bin/kraker /usr/bin/menu

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}✔ INSTALACIÓN COMPLETADA CON ÉXITO!${NC}"
echo -e "${YELLOW}Escribe 'kraker' o 'menu' para abrir el panel.${NC}"
echo -e "${CYAN}======================================================${NC}"

sleep 2
kraker

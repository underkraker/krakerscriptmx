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

# Install Git
echo -e "${YELLOW}[*] Verificando Git...${NC}"
apt update -y > /dev/null 2>&1
apt install -y git curl > /dev/null 2>&1

# Clone Repository
echo -e "${YELLOW}[*] Descargando Panel...${NC}"
REPO_DIR="/root/kraker_master"
if [[ -d "$REPO_DIR" ]]; then
    rm -rf "$REPO_DIR"
fi
git clone https://github.com/underkraker/krakerscriptmx.git "$REPO_DIR" > /dev/null 2>&1

# Set Permissions
echo -e "${YELLOW}[*] Configurando permisos...${NC}"
chmod +x "$REPO_DIR/menu.sh"
chmod +x "$REPO_DIR/scripts"/*.sh
chmod +x "$REPO_DIR/scripts/KRAKER_User.sh"

# Create Shortcut
echo -e "${YELLOW}[*] Creando acceso directo 'kraker'...${NC}"
ln -sf "$REPO_DIR/menu.sh" /usr/bin/kraker
chmod +x /usr/bin/kraker

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}✔ INSTALACIÓN COMPLETADA CON ÉXITO!${NC}"
echo -e "${YELLOW}Escribe 'kraker' para abrir el panel en cualquier momento.${NC}"
echo -e "${CYAN}======================================================${NC}"

sleep 2
kraker

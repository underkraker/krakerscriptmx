#!/bin/bash
# KRAKER MASTER - Quick Installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/username/repo/main/install.sh)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 🛠️ Entorno No Interactivo para Ubuntu 22.04+
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

# 🛡️ MÓDULO DE VERIFICACIÓN MAESTRA (KRAKER SHIELD)
echo -e "${YELLOW}[*] Validando entorno de seguridad...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y curl jq wget git build-essential shc > /dev/null 2>&1

TEMP_SHIELD="/tmp/KRAKER_Shield.sh"
wget -qO "$TEMP_SHIELD" "https://raw.githubusercontent.com/underkraker/krakerscriptmx/main/scripts/KRAKER_Shield.sh"
source "$TEMP_SHIELD"
verify_license || { echo -e "${RED}[!] Error en la verificación.${NC}"; exit 1; }

# Install Dependencies (Essential Pack)
echo -e "${YELLOW}[*] Instalando dependencias críticas...${NC}"
apt-get install -y ufw lsof openssl net-tools screen > /dev/null 2>&1

# Clone Repository
echo -e "${YELLOW}[*] Descargando Panel...${NC}"
REPO_DIR="/root/kraker_master"
[[ -d "$REPO_DIR" ]] && rm -rf "$REPO_DIR"
git clone https://github.com/underkraker/krakerscriptmx.git "$REPO_DIR" > /dev/null 2>&1

# 🔐 CIFRADO DE SEGURIDAD (SHC)
echo -e "${CYAN}[*] Protegiendo código fuente (Cifrado SHC)...${NC}"
cd "$REPO_DIR"
# Compilar Menu Principal
shc -v -r -f menu.sh -o menu_bin > /dev/null 2>&1
mv menu_bin menu.sh
rm -f menu.sh.x.c

# Compilar todos los scripts internos
for script in scripts/*.sh; do
    if [[ -f "$script" ]]; then
        shc -v -r -f "$script" -o "${script}_bin" > /dev/null 2>&1
        mv "${script}_bin" "$script"
        rm -f "${script}.x.c"
    fi
done

# Set Permissions
echo -e "${YELLOW}[*] Configurando permisos y Banner Global...${NC}"
chmod +x menu.sh
chmod +x scripts/*
source "$REPO_DIR/scripts/utils.sh" > /dev/null 2>&1 || true
setup_motd > /dev/null 2>&1 || true

# Create Shortcuts
echo -e "${YELLOW}[*] Creando accesos directos 'kraker' y 'menu'...${NC}"
ln -sf "$REPO_DIR/menu.sh" /usr/bin/kraker
ln -sf "$REPO_DIR/menu.sh" /usr/bin/menu
chmod +x /usr/bin/kraker /usr/bin/menu

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}✔ INSTALACIÓN COMPLETADA Y CIFRADA CON ÉXITO!${NC}"
echo -e "${YELLOW}Escribe 'kraker' o 'menu' para abrir el panel protegido.${NC}"
echo -e "${CYAN}======================================================${NC}"

sleep 2
kraker

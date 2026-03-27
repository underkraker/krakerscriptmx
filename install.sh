#!/bin/bash
# Instalador Automático de Gaming VPS Script

# Definir Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}     Preparando Servidor e Instalando Panel...        ${NC}"
echo -e "${CYAN}${BOLD}======================================================${NC}"

# Validar ROOT
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Error: Por favor, ejecuta el instalador como ROOT (sudo su o sudo bash).${NC}"
  exit 1
fi

# Actualizar e instalar base
echo -e "\n${CYAN}[*] Instalando dependencias base en el VPS...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y wget curl > /dev/null 2>&1

# Descargar el menú desde GitHub (Raw)
echo -e "${CYAN}[*] Descargando Panel desde el repositorio de GitHub...${NC}"
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/underkraker/scriptgamer/main/menu.sh"

if [ -f /usr/bin/menu ]; then
    # Otorgar permisos de dueño y ejecución universal
    chmod +x /usr/bin/menu
    
    echo -e "\n${GREEN}${BOLD}[✔] INSTALACIÓN COMPLETADA CON ÉXITO.${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo -e " 🎮 A partir de ahora, solo escribe el comando: ${GREEN}${BOLD}menu${NC}"
    echo -e " en cualquier parte de la consola para abrir el panel."
    echo -e "${CYAN}======================================================${NC}\n"
else
    echo -e "${RED}[x] Error catastrófico: No se pudo conectar a GitHub o el archivo no existe.${NC}"
    echo -e "Revisa tu conexión o asegúrate de que el repositorio sea público."
fi

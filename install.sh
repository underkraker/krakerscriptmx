#!/bin/bash
# Instalador AutomÃ¡tico de Gaming VPS Script

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
  echo -e "${RED}âŒ Error: Por favor, ejecuta el instalador como ROOT (sudo su o sudo bash).${NC}"
  exit 1
fi

# Actualizar e instalar base
echo -e "\n${CYAN}[*] Instalando dependencias base en el VPS...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y wget curl jq git net-tools iproute2 cron ca-certificates iptables > /dev/null 2>&1

# NUEVO: MÃ³dulo de Seguridad Maestro
echo -e "\n${CYAN}======================================================${NC}"
echo -e "${WHITE}${BOLD}      INGRESA TU KEY DE INSTALACIÃ“N${NC}"
echo -e "${CYAN}======================================================${NC}"
echo -e -n "${YELLOW}KEY: ${NC}"
read USER_KEY

if [ -z "$USER_KEY" ]; then
    echo -e "${RED}âŒ Error: La KEY no puede estar vacÃ­a.${NC}"
    exit 1
fi

# Validar con el Bot
echo -e "${CYAN}[*] Validando licencia con el servidor central...${NC}"
RESPONSE=$(curl -s "http://34.201.40.170:5000/api/validar?key=$USER_KEY")
STATUS=$(echo "$RESPONSE" | jq -r '.status')

if [ "$STATUS" == "success" ]; then
    OWNER=$(echo "$RESPONSE" | jq -r '.owner')
    echo -e "${GREEN}âœ… ACCESO CONCEDIDO: Bienvenido @$OWNER${NC}"
    sleep 2
else
    echo -e "${RED}âŒ ACCESO DENEGADO: Key invÃ¡lida o ya utilizada.${NC}"
    echo -e "${RED}Contacta a @underkraker para adquirir una licencia.${NC}"
    exit 1
fi

# Despliegue Directo de Marca Blanca
# Despliegue de la Suite KRAKER MASTER
echo -e "\n\[*] Iniciando despliegue de la Suite Modular v12.0...\"
DIR_BASE="/etc/gaming_vps"
mkdir -p $DIR_BASE
echo -e "\[*] Sincronizando repositorio con la VPS...\"
rm -rf $DIR_BASE/* > /dev/null 2>&1
git clone https://github.com/underkraker/scriptgamer $DIR_BASE > /dev/null 2>&1

if [ -f $DIR_BASE/menu.sh ]; then
    chmod +x $DIR_BASE/menu.sh $DIR_BASE/scripts/*.sh
    ln -sf $DIR_BASE/menu.sh /usr/bin/menu
    
    # Personalización
    echo -e "\n\======================================================\"
    echo -e "\\      PERSONALIZACIÓN KRAKER MASTER\"
    echo -e "\======================================================\"
    read -p "¿Nombre para el Panel? (Ej: KRAKER): " P_NAME
    read -p "¿Eslogan? (Ej: PREMIUM): " SLOGAN
    [ -n "" ] && echo "" > $DIR_BASE/panel_name.txt || echo "KRAKER" > $DIR_BASE/panel_name.txt
    [ -n "" ] && echo "" > $DIR_BASE/slogan.txt
    
    echo -e "\n\\[✔] INSTALACIÓN COMPLETADA.\"
    echo -e "Escribe '\menu\' para comenzar."
else
    echo -e "\[x] Error al descargar los archivos.\"
    exit 1
fi
    echo -e "${RED}[x] Error catastrÃ³fico: No se pudo conectar a GitHub o el archivo no existe.${NC}"
    echo -e "Revisa tu conexiÃ³n o asegÃºrate de que el repositorio sea pÃºblico."
fi

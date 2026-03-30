#!/bin/bash
# KRAKER MASTER - CENTRAL BOT DEPLOYER 🐲🛡️🚀
# Versión 1.0 (DuckDNS & Master License Integration)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}    🐲 DESPLEGADOR DE BOT MAESTRO KRAKER 🐲${NC}"
echo -e "${CYAN}======================================================${NC}"

# Validar ROOT
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Error: Ejecuta este script como ROOT.${NC}"
   exit 1
fi

# 📥 Instalación de Dependencias
echo -e "${YELLOW}[*] Instalando dependencias (Python3, Pip, Flask, Telebot, Screen)...${NC}"
apt update -y > /dev/null 2>&1
apt install -y python3 python3-pip git screen curl jq > /dev/null 2>&1
pip3 install pyTelegramBotAPI Flask paramiko --break-system-packages > /dev/null 2>&1

# 🏗️ Preparar Repositorio del Bot
echo -e "${YELLOW}[*] Descargando código del Bot (botscriptgamer)...${NC}"
BOT_DIR="/root/kraker_bot"
rm -rf "$BOT_DIR"
git clone https://github.com/underkraker/botscriptgamer.git "$BOT_DIR" > /dev/null 2>&1

# ⚙️ Configuración del Maestro
echo -e "\n${CYAN}------------------------------------------------------${NC}"
echo -e "${WHITE}CONFIGURACIÓN DEL BOT CENTRAL${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"
read -p "🚀 Ingrese el TOKEN de Telegram: " BOT_TOKEN
read -p "👑 Ingrese su ADMIN_ID (Ej: 12345678): " ADMIN_ID
read -p "🦆 Ingrese su Dominio DuckDNS (Ej: krakervps): " DUCK_DOMAIN
read -p "🗝️ Ingrese su DuckDNS TOKEN: " DUCK_TOKEN
echo -e "${CYAN}------------------------------------------------------${NC}"

# 📄 Crear config.py dinámico
cat <<EOF > "$BOT_DIR/config.py"
TOKEN = "$BOT_TOKEN"
ADMIN_ID = $ADMIN_ID
VERSION = "v13.0 Master Shield 🛡️"
INSTALL_CMD = "bash <(curl -fsSL https://raw.githubusercontent.com/underkraker/krakerscriptmx/main/install.sh)"
API_KEY = "KRAKER_MASTER_ELITE"
EOF

# 🛠️ Configurar Auto-Update de IP (DuckDNS)
echo -e "${YELLOW}[*] Configurando Auto-Update de IP vía DuckDNS...${NC}"
cat <<EOF > /usr/bin/kraker_duckdns
echo url="https://www.duckdns.org/update?domains=$DUCK_DOMAIN&token=$DUCK_TOKEN&ip=" | curl -k -K -
EOF
chmod +x /usr/bin/kraker_duckdns
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/kraker_duckdns >/dev/null 2>&1") | crontab -
/usr/bin/kraker_duckdns # Primera actualización

# 🚀 Iniciar el Bot en Pantalla (Screen)
echo -e "${YELLOW}[*] Iniciando el Bot en modo persistente (Screen)...${NC}"
screen -dmS master_bot python3 "$BOT_DIR/bot.py"

# Fin del Proceso
echo -e "\n${GREEN}✔ BOT DESPLEGADO CON ÉXITO!${NC}"
echo -e "${WHITE}Dominio Activo: ${CYAN}http://$DUCK_DOMAIN.duckdns.org:5000${NC}"
echo -e "${WHITE}Comando para ver el Bot: ${YELLOW}screen -r master_bot${NC}"
echo -e "${CYAN}======================================================${NC}"

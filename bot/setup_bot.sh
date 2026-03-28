#!/bin/bash
# Master Bot Setup Script - Gaming VPS Bot
# Instalador automático para el Bot de Gestión en la VPS Central (34.201.40.170)

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}     Instalando Master Bot en VPS Central...         ${NC}"
echo -e "${CYAN}${BOLD}======================================================${NC}"

# Validar ROOT
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Error: Por favor, ejecuta como ROOT.${NC}"
  exit 1
fi

# Instalar Dependencias
echo -e "\n${CYAN}[*] Instalando Python3, SQLite y Pip...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y python3 python3-pip python3-venv sqlite3 screen lsof > /dev/null 2>&1

# Directorio del Bot
mkdir -p /etc/gaming_vps/bot
cd /etc/gaming_vps/bot

# Descargar archivos (desde el mismo repo scriptgamer)
echo -e "${CYAN}[*] Descargando archivos del Bot...${NC}"
wget -qO bot.py "https://raw.githubusercontent.com/underkraker/scriptgamer/main/bot/bot.py"
wget -qO database.py "https://raw.githubusercontent.com/underkraker/scriptgamer/main/bot/database.py"
wget -qO config.py "https://raw.githubusercontent.com/underkraker/scriptgamer/main/bot/config.py"
wget -qO requirements.txt "https://raw.githubusercontent.com/underkraker/scriptgamer/main/bot/requirements.txt"
wget -qO migrate.py "https://raw.githubusercontent.com/underkraker/scriptgamer/main/bot/migrate.py"

# Instalar requerimientos
echo -e "${CYAN}[*] Instalando librerías de Python...${NC}"
pip3 install -r requirements.txt > /dev/null 2>&1

# Inicializar Base de Datos
echo -e "${CYAN}[*] Inicializando Base de Datos y Migraciones...${NC}"
python3 migrate.py > /dev/null 2>&1

# Configurar Servicio Systemd
echo -e "${CYAN}[*] Creando Servicio del Sistemavps-bot.service...${NC}"
cat > /etc/systemd/system/vps-bot.service <<EOF
[Unit]
Description=Gaming VPS Management Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/gaming_vps/bot
ExecStart=/usr/bin/python3 /etc/gaming_vps/bot/bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vps-bot >/dev/null 2>&1
systemctl restart vps-bot >/dev/null 2>&1

# Abrir Puerto 5000 (API de Validación)
iptables -I INPUT -p tcp --dport 5000 -j ACCEPT
iptables-save > /etc/iptables.rules 2>/dev/null

echo -e "\n${GREEN}${BOLD}[✔] EL BOT HA SIDO INSTALADO Y ESTÁ EN EJECUCIÓN.${NC}"
echo -e "${CYAN}======================================================${NC}"
echo -e " ⚡ Puerto de API: ${WHITE}5000 (Abierto)${NC}"
echo -e " 📁 Ubicación: ${WHITE}/etc/gaming_vps/bot/${NC}"
echo -e " 📝 Logs: ${WHITE}journalctl -u vps-bot -f${NC}"
echo -e "${CYAN}======================================================${NC}\n"

#!/bin/bash
# KRAKER MASTER - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "XRAY REALITY SETUP"
install_deps curl jq openssl coreutils ufw lsof

# 2. Instalación Maestro Xray
install_xray() {
    msg_header "MASTER XRAY INSTALLER"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando núcleo oficial de Xray...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    # Verificación de Integridad
    if [[ -s /usr/local/bin/xray ]]; then
        echo -e "${GREEN}[✔] Binario Xray Verificado ($(ls -lh /usr/local/bin/xray | awk '{print $5}'))${NC}"
    else
        echo -e "${RED}[!] Error: Binario no detectado. Reintentando con estático...${NC}"
        wget -qO /usr/local/bin/xray "https://github.com/underkraker/xray-static/raw/main/xray"
        chmod +x /usr/local/bin/xray
    fi
}

# 3. Datos y Configuración UNIFICADA
install_xray
UUID=$(/usr/local/bin/xray uuid)
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
IP_PUB=$(get_ip)

read -p "Ingresa el SNI Bug para REALITY: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

PORT=443
if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
    PORT=4433
    echo -e "${YELLOW}Aviso: Puerto 443 ocupado. Usando: $PORT${NC}"
fi

# Crear Configuración Base (Master)
mkdir -p /usr/local/etc/xray
cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "vless", "tag": "REALITY_INBOUND",
        "settings": {"clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": "$BUG:443", "xver": 0,
                "serverNames": ["$BUG"], "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"]
            }
        },
        "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 4. Activación Maestro
systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}[✔] SERVICIO XRAY CORRIENDO EN PUERTO $PORT${NC}"
else
    echo -e "${RED}[!] Error: El servicio no pudo iniciar. Revisa 'journalctl -u xray'${NC}"
fi

LINK="vless://$UUID@$IP_PUB:$PORT?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_REALITY"

msg_header "REALITY INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER REALITY ACTIVADO!${NC}"
echo -e "${YELLOW}Enlace :${NC} $LINK"
echo -e "${BARRA}"

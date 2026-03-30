#!/bin/bash
# KRAKER MASTER - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "XRAY REALITY SETUP"
install_deps curl jq openssl coreutils ufw lsof

# 2. Maestro Xray y Verificación de Integridad
install_xray() {
    msg_header "MASTER XRAY INSTALLER"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando núcleo oficial de Xray...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    # Verificación de Binario
    if [[ -s /usr/local/bin/xray ]]; then
        echo -e "${GREEN}[✔] Binario Xray Verificado ($(ls -lh /usr/local/bin/xray | awk '{print $5}'))${NC}"
    else
        echo -e "${RED}[!] Error: No se detectó el binario. Instalando estático...${NC}"
        wget -qO /usr/local/bin/xray "https://github.com/underkraker/xray-static/raw/main/xray"
        chmod +x /usr/local/bin/xray
    fi
}

# 3. Selección de Modo (Nivel Master)
msg_header "VLESS MASTER SELECTOR"
echo -e "${YELLOW}[1] > ${WHITE}MODO REALITY (Sigilo - Auto SNI Google)${NC}"
echo -e "${YELLOW}[2] > ${WHITE}MODO TLS DIRECTO (Usar IP o Dominio Propio)${NC}"
echo -e "${BARRA}"
read -p "Seleccione modo [1-2]: " MODE

install_xray
UUID=$(/usr/local/bin/xray uuid)
IP_PUB=$(get_ip)
PORT=443

# Liberar puertos en conflicto
systemctl stop nginx apache2 stunnel4 > /dev/null 2>&1

if [[ "$MODE" == "2" ]]; then
    # MODO TLS DIRECTO (Igual que SSL)
    read -p "Ingresa tu Dominio (O deja vacío para usar IP): " DOMAIN
    [[ -z $DOMAIN ]] && DOMAIN=$IP_PUB
    
    echo -e "${YELLOW}[*] Generando Certificados para $DOMAIN...${NC}"
    mkdir -p /etc/kraker_xray
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_xray/server.key -out /etc/kraker_xray/server.crt -subj "/CN=$DOMAIN" -days 3650 2>/dev/null
    
    # Configuración VLESS-TLS
    cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443, "protocol": "vless",
        "settings": {"clients": [{"id": "$UUID"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "tls",
            "tlsSettings": {
                "certificates": [{"certificateFile": "/etc/kraker_xray/server.crt", "keyFile": "/etc/kraker_xray/server.key"}]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    LINK="vless://$UUID@$IP_PUB:443?security=tls&sni=$DOMAIN&type=tcp#KRAKER_VLESS_TLS"
else
    # MODO REALITY (Auto-Google)
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
    PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
    SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
    BUG="www.google.com"

    cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443, "protocol": "vless",
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
    LINK="vless://$UUID@$IP_PUB:443?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_REALITY"
fi

# 4. Activación Maestro
systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1

msg_header "INSTALACIÓN COMPLETADA"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✔ KRAKER VLESS ACTIVADO EXITOSAMENTE!${NC}"
    echo -e "${YELLOW}Enlace :${NC} $LINK"
else
    echo -e "${RED}[!] Error: El servicio no inició. Revisa puertos ocupados.${NC}"
fi
echo -e "${BARRA}"

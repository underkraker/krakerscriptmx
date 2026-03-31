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
install_xray_modular

# 3. Selección de Modo (Nivel Master)
msg_header "VLESS MASTER SELECTOR"
echo -e "${YELLOW}[1] > ${WHITE}MODO REALITY (Sigilo - Auto SNI Google)${NC}"
echo -e "${YELLOW}[2] > ${WHITE}MODO TLS DIRECTO (Usar IP o Dominio Propio)${NC}"
echo -e "${BARRA}"
read -p "Seleccione modo [1-2]: " MODE

UUID=$(/usr/local/bin/xray uuid)
IP_PUB=$(get_ip)
PORT=443

# Liberar puertos en conflicto
pkill -9 -f xray > /dev/null 2>&1
fuser -k 443/tcp > /dev/null 2>&1

if [[ "$MODE" == "2" ]]; then
    # MODO TLS DIRECTO
    read -p "Ingresa tu Dominio (O deja vacío para usar IP): " DOMAIN
    [[ -z $DOMAIN ]] && DOMAIN=$IP_PUB
    
    echo -e "${YELLOW}[*] Generando Certificados para $DOMAIN...${NC}"
    mkdir -p /etc/kraker_xray
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_xray/server.key -out /etc/kraker_xray/server.crt -subj "/CN=$DOMAIN" -days 3650 2>/dev/null
    
    # Configuración VLESS-TLS Modular
    cat > /usr/local/etc/xray/conf.d/reality.json <<EOF
{
    "inbounds": [{
        "port": 443, "protocol": "vless", "tag": "REALITY_INBOUND",
        "settings": {"clients": [{"id": "$UUID"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "tls",
            "tlsSettings": {
                "certificates": [{"certificateFile": "/etc/kraker_xray/server.crt", "keyFile": "/etc/kraker_xray/server.key"}]
            }
        }
    }]
}
EOF
    LINK="vless://$UUID@$IP_PUB:443?security=tls&sni=$DOMAIN&type=tcp#KRAKER_VLESS_TLS"
else
    # MODO REALITY (UNIVERSAL SNI BUG)
    # En este modo, el servidor acepta cualquier Host que el cliente le mande
    BUG="www.google.com"
    
    KEYS=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep -i "Private" | awk '{print $NF}' | tr -d ' ')
    PUBLIC_KEY=$(echo "$KEYS" | grep -i "Public" | awk '{print $NF}' | tr -d ' ')
    SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)

    cat > /usr/local/etc/xray/conf.d/reality.json <<EOF
{
    "inbounds": [{
        "port": 443, "protocol": "vless", "tag": "REALITY_INBOUND",
        "settings": {"clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": "$BUG:443", "xver": 0,
                "serverNames": ["$BUG", "www.microsoft.com", "www.netflix.com"], 
                "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"]
            }
        },
        "sniffing": {
            "enabled": true, 
            "destOverride": ["http", "tls"],
            "routeOnly": false
        }
    }]
}
EOF
    LINK="vless://$UUID@$IP_PUB:443?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_MASTER_REALITY"
fi



# 4. Activación Maestro
systemctl restart xray > /dev/null 2>&1
ufw allow 443/tcp > /dev/null 2>&1

msg_header "INSTALACIÓN COMPLETADA"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✔ KRAKER VLESS ACTIVADO EXITOSAMENTE!${NC}"
    echo -e "${YELLOW}Enlace :${NC} $LINK"
else
    echo -e "${RED}[!] Error: Xray no inició. Revisando Puerto 443...${NC}"
fi
echo -e "${BARRA}"

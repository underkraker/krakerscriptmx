#!/bin/bash
# KRAKER MASTER - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "XRAY REALITY SETUP"
install_deps curl jq openssl coreutils ufw lsof

# 2. Xray Installation (Expert Mode)
install_xray() {
    echo -e "${YELLOW}[*] Verificando Xray-core...${NC}"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Descargando Xray Core...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${RED}[!] Error: No se pudo instalar Xray Core.${NC}"
        exit 1
    fi
}

# 3. Security IDs & Keys
install_xray
UUID=$(/usr/local/bin/xray uuid)
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
IP_PUB=$(get_ip)

# 4. Interactivity
read -p "Ingresa el SNI Bug para REALITY: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

PORT=443
if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
    PORT=4433 # Fallback si 443 está ocupado
    echo -e "${YELLOW}Aviso: Puerto 443 ocupado. Usando: $PORT${NC}"
fi

# 5. Configuración con Coexistencia (JQ)
mkdir -p /usr/local/etc/xray
cat > /usr/local/etc/xray/reality_inbound.json <<EOF
{
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
}
EOF

if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# Eliminar inbound anterior de REALITY si existe para evitar duplicados
jq 'del(.inbounds[] | select(.tag == "REALITY_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
# Añadir nuevo inbound
jq --argjson new "$(cat /usr/local/etc/xray/reality_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/reality_inbound.json

# 6. Service & Finalizacion
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1

LINK="vless://$UUID@$IP_PUB:$PORT?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_VPS_REALITY"

msg_header "REALITY INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER REALITY INSTALADO CON ÉXITO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}SNI Bug:${NC} $BUG"
echo -e "${YELLOW}Puerto :${NC} $PORT"
echo -e "${BARRA}"
echo -e "${GREEN}ENLACE VLESS:${NC}\n$LINK"
echo -e "${BARRA}"

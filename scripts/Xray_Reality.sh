#!/bin/bash
# KRAKER MASTER - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "XRAY REALITY SETUP"
install_deps curl jq openssl coreutils ufw lsof

# 2. Xray Installation
echo -e "${YELLOW}[*] Verificando Xray-core...${NC}"
if [[ ! -f /usr/local/bin/xray ]]; then
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
fi

# 3. Security IDs & Keys
echo -e "${YELLOW}[*] Generando Identificadores de Seguridad...${NC}"
UUID=$(/usr/local/bin/xray uuid)
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
IP_PUB=$(get_ip)

# 4. Interactivity (SNI Bug)
echo -e "${CYAN}Ingresa el SNI Bug para REALITY (ej: cdn-global.configcat.com)${NC}"
read -p "SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

# Port Selection (Priority 443)
PORT=443
if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
    PORT=$(( RANDOM % 5000 + 40000 ))
    echo -e "${YELLOW}Aviso: Puerto 443 ocupado. Usando: $PORT${NC}"
fi

# 5. Configuration (JSON)
cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "vless",
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

# 6. Service & Banner
setup_motd
ufw allow $PORT/tcp > /dev/null 2>&1
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

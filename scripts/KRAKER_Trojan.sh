#!/bin/bash
# KRAKER MASTER - TROJAN WS + TLS
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Interactiva
msg_header "TROJAN WS + TLS SETUP"
install_deps curl jq openssl coreutils ufw lsof

read -p "Introduce tu SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

read -p "Puerto para Trojan [2053]: " PORT
[[ -z $PORT ]] && PORT=2053

PASS=$(openssl rand -hex 8)
IP=$(get_ip)

# 2. Xray Installation (Expert Mode)
install_xray() {
    msg_header "VERIFICANDO XRAY PARA TROJAN"
    if [[ ! -s /usr/local/bin/xray-trojan ]]; then
        echo -e "${YELLOW}[*] Instalando Binario Xray dedicado...${NC}"
        cp /usr/local/bin/xray /usr/local/bin/xray-trojan > /dev/null 2>&1 || \
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
        cp /usr/local/bin/xray /usr/local/bin/xray-trojan 2>/dev/null
    fi
}

# 3. Datos y Configuración
install_xray
PASS=$(openssl rand -hex 8)
IP=$(get_ip)

echo -e "${YELLOW}[*] Generando certificados Trojan...${NC}"
mkdir -p /etc/kraker_trojan
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_trojan/server.key -out /etc/kraker_trojan/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

cat << EOM > /etc/kraker_trojan/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "trojan",
        "settings": {"clients": [{"password": "$PASS"}], "decryption": "none"},
        "streamSettings": {
            "network": "ws", "security": "tls",
            "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_trojan/server.crt", "keyFile": "/etc/kraker_trojan/server.key"}]},
            "wsSettings": {"path": "/krakervps"}
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOM

# 4. Servicio Systemd Independiente
cat << EOF > /etc/systemd/system/kraker-trojan.service
[Unit]
Description=KRAKER MASTER - Trojan Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray-trojan run -c /etc/kraker_trojan/config.json
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kraker-trojan > /dev/null 2>&1
systemctl restart kraker-trojan > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

LINK="trojan://$PASS@$IP:$PORT?security=tls&sni=$BUG&fp=chrome&type=ws&path=/krakervps#KRAKER_TROJAN"
msg_header "TROJAN INSTALADO (PUERTO $PORT)"
echo -e "${GREEN}✔ KRAKER TROJAN ACTIVADO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

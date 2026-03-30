#!/bin/bash
# KRAKER MASTER - VMess WS + TLS
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Interactiva
msg_header "VMESS WS + TLS SETUP"
install_deps curl jq openssl coreutils ufw lsof

read -p "Introduce tu SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

read -p "Puerto para VMess [2083]: " PORT
[[ -z $PORT ]] && PORT=2083

# 2. Xray Installation (Expert Mode)
install_xray() {
    echo -e "${YELLOW}[*] Verificando Xray-core...${NC}"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Descargando Xray Core...${NC}"
    msg_header "VERIFICANDO XRAY PARA VMESS"
    if [[ ! -s /usr/local/bin/xray-vmess ]]; then
        echo -e "${YELLOW}[*] Instalando Binario Xray dedicado...${NC}"
        cp /usr/local/bin/xray /usr/local/bin/xray-vmess > /dev/null 2>&1 || \
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
        cp /usr/local/bin/xray /usr/local/bin/xray-vmess 2>/dev/null
    fi
}

# 3. Datos y Configuración
install_xray
UUID=$(/usr/local/bin/xray-vmess uuid 2>/dev/null || echo "kraker-uuid-$(date +%s)")
IP=$(get_ip)

echo -e "${YELLOW}[*] Generando certificados WS...${NC}"
mkdir -p /etc/kraker_vmess
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_vmess/server.key -out /etc/kraker_vmess/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

cat << EOM > /etc/kraker_vmess/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "vmess",
        "settings": {"clients": [{"id": "$UUID", "alterId": 0}]},
        "streamSettings": {
            "network": "ws", "security": "tls",
            "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_vmess/server.crt", "keyFile": "/etc/kraker_vmess/server.key"}]},
            "wsSettings": { "path": "/krakervps" }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOM

# 4. Servicio Systemd Independiente
cat << EOF > /etc/systemd/system/kraker-vmess.service
[Unit]
Description=KRAKER MASTER - VMess Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray-vmess run -c /etc/kraker_vmess/config.json
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kraker-vmess > /dev/null 2>&1
systemctl restart kraker-vmess > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

VMESS_JSON=$(cat << EOM
{ "v": "2", "ps": "KRAKER_VMESS", "add": "$IP", "port": "$PORT", "id": "$UUID", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$BUG", "path": "/krakervps", "tls": "tls", "sni": "$BUG" }
EOM
)
LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"

msg_header "VMESS INSTALADO (PUERTO $PORT)"
echo -e "${GREEN}✔ KRAKER VMESS ACTIVADO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

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
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
}

# 3. Configuración con Coexistencia (JQ)
install_xray
UUID=$(/usr/local/bin/xray uuid)
IP=$(get_ip)

# 2. Certificados y Directorios
echo -e "${YELLOW}[*] Generando certificados...${NC}"
mkdir -p /etc/kraker_vmess
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_vmess/server.key -out /etc/kraker_vmess/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

echo -e "${YELLOW}[*] Configurando Inbound VMess...${NC}"
cat << EOM > /usr/local/etc/xray/vmess_inbound.json
{
    "port": $PORT, "protocol": "vmess", "tag": "VMESS_INBOUND",
    "settings": {"clients": [{"id": "$UUID", "alterId": 0}]},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_vmess/server.crt", "keyFile": "/etc/kraker_vmess/server.key"}]},
        "wsSettings": { "path": "/krakervps" }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# Eliminar inbound anterior de VMESS si existe para evitar duplicados
jq 'del(.inbounds[] | select(.tag == "VMESS_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
# Añadir nuevo inbound
jq --argjson new "$(cat /usr/local/etc/xray/vmess_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/vmess_inbound.json

# 4. Finalización
setup_motd
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1

VMESS_JSON=$(cat << EOM
{ "v": "2", "ps": "KRAKER_VPS_VMESS", "add": "$IP", "port": "$PORT", "id": "$UUID", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$BUG", "path": "/krakervps", "tls": "tls", "sni": "$BUG" }
EOM
)
LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"

msg_header "VMESS INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER VMESS INSTALADO CON ÉXITO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

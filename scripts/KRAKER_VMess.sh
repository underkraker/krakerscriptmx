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

# 2. Xray Core Integrity (Master Check)
install_xray() {
    msg_header "VERIFICANDO NÚCLEO XRAY"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando Xray-core oficialmente...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    if [[ -s /usr/local/bin/xray ]]; then
        echo -e "${GREEN}[✔] Núcleo Xray Detectado ($(ls -lh /usr/local/bin/xray | awk '{print $5}'))${NC}"
    else
        echo -e "${RED}[!] Error Fatal: No se pudo instalar Xray Core.${NC}"
        exit 1
    fi
}

# 3. Configuración con Coexistencia JQ
install_xray
UUID=$(/usr/local/bin/xray uuid)
IP=$(get_ip)

echo -e "${YELLOW}[*] Generando certificados y configuración VMess...${NC}"
mkdir -p /etc/kraker_vmess
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_vmess/server.key -out /etc/kraker_vmess/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

cat << EOM > /usr/local/etc/xray/vmess_inbound.json
{
    "port": $PORT, "protocol": "vmess", "tag": "VMESS_INBOUND",
    "settings": {"clients": [{"id": "$UUID", "alterId": 0}]},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_vmess/server.crt", "keyFile": "/etc/kraker_vmess/server.key"}]},
        "wsSettings": { "path": "/krakervps" }
    }
}
EOM

# Inyectar en Configuración Maestra
if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

jq 'del(.inbounds[] | select(.tag == "VMESS_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
jq --argjson new "$(cat /usr/local/etc/xray/vmess_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/vmess_inbound.json

# 4. Activación y Verificación
systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}[✔] SERVICIO XRAY REINICIADO CON ÉXITO${NC}"
else
    echo -e "${RED}[!] Error: El servicio falló al reiniciar. Revisa 'journalctl -u xray'${NC}"
fi

VMESS_JSON=$(cat << EOM
{ "v": "2", "ps": "KRAKER_VMESS", "add": "$IP", "port": "$PORT", "id": "$UUID", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$BUG", "path": "/krakervps", "tls": "tls", "sni": "$BUG" }
EOM
)
LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"

msg_header "VMESS INSTALADO (PUERTO $PORT)"
echo -e "${GREEN}✔ KRAKER VMESS COEXISTIENDO CON ÉXITO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

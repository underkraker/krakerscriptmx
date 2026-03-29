#!/bin/bash
# KRAKER MASTER - SHADOWSOCKS WS + TLS
# Versión Elite Auditada - Velocidad Pura para Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Interactiva
msg_header "SHADOWSOCKS WS + TLS SETUP"
install_deps curl jq openssl coreutils ufw lsof

BUG=$(get_sni_choice)

read -p "Puerto para Shadowsocks [2087]: " PORT
[[ -z $PORT ]] && PORT=2087

PASS=$(openssl rand -hex 12)
IP=$(get_ip)

# 2. Certificados y Directorios
echo -e "${YELLOW}[*] Generando certificados...${NC}"
mkdir -p /etc/kraker_shadowsocks
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_shadowsocks/server.key -out /etc/kraker_shadowsocks/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# 3. Integración con Xray (JQ)
echo -e "${YELLOW}[*] Configurando Xray-core...${NC}"
cat << EOM > /usr/local/etc/xray/temp_ss.json
{
    "port": $PORT, "protocol": "shadowsocks",
    "settings": {"method": "aes-256-gcm", "password": "$PASS"},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_shadowsocks/server.crt", "keyFile": "/etc/kraker_shadowsocks/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ -f /usr/local/etc/xray/config.json ]; then
    jq --argjson new_inbound "$(cat /usr/local/etc/xray/temp_ss.json)" '.inbounds += [$new_inbound]' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp && mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
else
    echo "{\"inbounds\": [$(cat /usr/local/etc/xray/temp_ss.json)], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# 4. Finalización
setup_motd
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
rm /usr/local/etc/xray/temp_ss.json

# Enlace Shadowsocks
SS_CORE="aes-256-gcm:$PASS@$IP:$PORT"
ENCODED=$(echo -n "$SS_CORE" | base64 | tr -d '\n')
LINK="ss://$ENCODED?plugin=v2ray-plugin%3Btls%3Bhost%3D$BUG%3Bpath%3D%2Fkrakervps#KRAKER_VPS_SHADOWSOCKS"

msg_header "SHADOWSOCKS INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER SHADOWSOCKS INSTALADO CON ÉXITO!${NC}"
echo -e "${YELLOW}Enlace SS:${NC} $LINK"
echo -e "${BARRA}"
echo -e "Copia el enlace y asegura de permitir certificados inseguros en tu App."
echo -e "${BARRA}"

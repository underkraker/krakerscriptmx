#!/bin/bash
# KRAKER MASTER - TROJAN WS + TLS
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Interactiva
msg_header "TROJAN WS + TLS SETUP"
install_deps curl jq openssl coreutils ufw lsof

BUG=$(get_sni_choice)

read -p "Puerto para Trojan [2053]: " PORT
[[ -z $PORT ]] && PORT=2053

PASS=$(openssl rand -hex 8)
IP=$(get_ip)

# 2. Certificados y Directorios
echo -e "${YELLOW}[*] Generando certificados...${NC}"
mkdir -p /etc/kraker_trojan
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_trojan/server.key -out /etc/kraker_trojan/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# 3. Integración con Xray (JQ)
echo -e "${YELLOW}[*] Configurando Xray-core...${NC}"
cat << EOM > /usr/local/etc/xray/temp_trojan.json
{
    "port": $PORT, "protocol": "trojan",
    "settings": {"clients": [{"password": "$PASS"}], "decryption": "none"},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_trojan/server.crt", "keyFile": "/etc/kraker_trojan/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ -f /usr/local/etc/xray/config.json ]; then
    jq --argjson new_inbound "$(cat /usr/local/etc/xray/temp_trojan.json)" '.inbounds += [$new_inbound]' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp && mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
else
    echo "{\"inbounds\": [$(cat /usr/local/etc/xray/temp_trojan.json)], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# 4. Finalización
setup_motd
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
rm /usr/local/etc/xray/temp_trojan.json

LINK="trojan://$PASS@$IP:$PORT?security=tls&sni=$BUG&fp=chrome&type=ws&path=/krakervps#KRAKER_VPS_TROJAN"
msg_header "TROJAN INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER TROJAN INSTALADO CON ÉXITO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

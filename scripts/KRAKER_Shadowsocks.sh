#!/bin/bash
# KRAKER MASTER - SHADOWSOCKS WS + TLS
# Versión Elite Auditada - Velocidad Pura para Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Master de Shadowsocks
msg_header "SHADOWSOCKS WS + TLS [MASTER SELECTOR]"
echo -e "${YELLOW}[1] > ${WHITE}MODO AUTO (Usar IP del VPS para el Túnel)${NC}"
echo -e "${YELLOW}[2] > ${WHITE}MODO DOMINIO (Usar tu propio Dominio)${NC}"
echo -e "${BARRA}"
read -p "Seleccione modo [1-2]: " SS_MODE

install_deps curl jq openssl coreutils ufw lsof
IP_PUB=$(get_ip)

if [[ "$SS_MODE" == "2" ]]; then
    read -p "Ingresa tu Dominio: " BUG
else
    BUG=$IP_PUB
fi
[[ -z $BUG ]] && BUG=$IP_PUB

# Puerto Detectado (Predeterminado 2096 - Puerto HTTPS Cloudflare)
PORT=2096
if ss -ntlp | grep -q ":2096 "; then
    PORT=2083
    echo -e "${YELLOW}[!] Puerto 2096 ocupado. Usando alternativo: $PORT${NC}"
fi

# 2. Certificados y Configuración
echo -e "${YELLOW}[*] Generando certificados y configuración Shadowsocks para $BUG...${NC}"
mkdir -p /etc/kraker_shadowsocks
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_shadowsocks/server.key -out /etc/kraker_shadowsocks/server.crt -subj "/CN=$BUG" -days 3650 2>/dev/null

PASS=$(openssl rand -hex 12)

cat << EOM > /usr/local/etc/xray/temp_ss.json
{
    "port": $PORT, "protocol": "shadowsocks", "tag": "SS_INBOUND",
    "settings": {"method": "aes-256-gcm", "password": "$PASS"},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_shadowsocks/server.crt", "keyFile": "/etc/kraker_shadowsocks/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

# Inyectar en Configuración Maestra con JQ
if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

jq 'del(.inbounds[] | select(.tag == "SS_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
jq --argjson new "$(cat /usr/local/etc/xray/temp_ss.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/temp_ss.json

# 3. Finalización y Reinicio
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1

# 4. Generar Enlace Shadowsocks
SS_CORE="aes-256-gcm:$PASS@$IP_PUB:$PORT"
ENCODED=$(echo -n "$SS_CORE" | base64 | tr -d '\n')
LINK="ss://$ENCODED?plugin=v2ray-plugin%3Btls%3Bhost%3D$BUG%3Bpath%3D%2Fkrakervps#KRAKER_SHADOWSOCKS"

msg_header "SHADOWSOCKS INSTALADO CON ÉXITO"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✔ KRAKER SHADOWSOCKS ACTIVO (PUERTO $PORT)${NC}"
    echo -e "${YELLOW}Enlace SS:${NC} $LINK"
else
    echo -e "${RED}[!] Error: Xray no inició. Revisa logs.${NC}"
fi
echo -e "${BARRA}"

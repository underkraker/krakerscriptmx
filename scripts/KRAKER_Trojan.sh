#!/bin/bash
# KRAKER MASTER - TROJAN WS + TLS
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Master de Trojan
msg_header "TROJAN WS + TLS [MASTER SELECTOR]"
echo -e "${YELLOW}[1] > ${WHITE}MODO AUTO (Usar IP del VPS para el Túnel)${NC}"
echo -e "${YELLOW}[2] > ${WHITE}MODO DOMINIO (Usar tu propio Dominio)${NC}"
echo -e "${BARRA}"
read -p "Seleccione modo [1-2]: " TR_MODE

install_deps curl jq openssl coreutils ufw lsof
IP_PUB=$(get_ip)

if [[ "$TR_MODE" == "2" ]]; then
    read -p "Ingresa tu Dominio: " BUG
else
    BUG=$IP_PUB
fi
[[ -z $BUG ]] && BUG=$IP_PUB

# Puerto Detectado (Predeterminado 2053)
PORT=2053
if ss -ntlp | grep -q ":2053 "; then
    PORT=2087
    echo -e "${YELLOW}[!] Puerto 2053 ocupado. Usando alternativo: $PORT${NC}"
fi

# 2. Xray Core Integrity (Master Check)
install_xray() {
    msg_header "VERIFICANDO NÚCLEO XRAY"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando núcleo oficial de Xray...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
}

# 3. Datos y Configuración
install_xray
PASS=$(openssl rand -hex 8)

echo -e "${YELLOW}[*] Generando certificados y configuración Trojan para $BUG...${NC}"
mkdir -p /etc/kraker_trojan
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_trojan/server.key -out /etc/kraker_trojan/server.crt -subj "/CN=$BUG" -days 3650 2>/dev/null

cat << EOM > /usr/local/etc/xray/trojan_inbound.json
{
    "port": $PORT, "protocol": "trojan", "tag": "TROJAN_INBOUND",
    "settings": {"clients": [{"password": "$PASS"}]},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_trojan/server.crt", "keyFile": "/etc/kraker_trojan/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    }
}
EOM

# Inyectar en Configuración Maestra con JQ
if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

jq 'del(.inbounds[] | select(.tag == "TROJAN_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
jq --argjson new "$(cat /usr/local/etc/xray/trojan_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/trojan_inbound.json

# 4. Activación y Verificación
systemctl daemon-reload
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

LINK="trojan://$PASS@$IP_PUB:$PORT?security=tls&sni=$BUG&fp=chrome&type=ws&path=/krakervps#KRAKER_TROJAN"
msg_header "TROJAN INSTALADO CON ÉXITO"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✔ KRAKER TROJAN ACTIVO (PUERTO $PORT)${NC}"
    echo -e "${YELLOW}Enlace:${NC} $LINK"
else
    echo -e "${RED}[!] Error: Xray no inició. Revisa logs.${NC}"
fi
echo -e "${BARRA}"

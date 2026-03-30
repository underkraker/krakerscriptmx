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

# 2. Xray Core Integrity (Master Check)
install_xray() {
    msg_header "VERIFICANDO NÚCLEO XRAY"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando núcleo oficial de Xray...${NC}"
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
PASS=$(openssl rand -hex 8)
IP=$(get_ip)

echo -e "${YELLOW}[*] Generando certificados y configuración Trojan...${NC}"
mkdir -p /etc/kraker_trojan
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_trojan/server.key -out /etc/kraker_trojan/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

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

# Inyectar en Configuración Maestra
if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

jq 'del(.inbounds[] | select(.tag == "TROJAN_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
jq --argjson new "$(cat /usr/local/etc/xray/trojan_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/trojan_inbound.json

# 4. Activación y Verificación
systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}[✔] SERVICIO XRAY REINICIADO (MODO TROJAN ADICIONADO)${NC}"
else
    echo -e "${RED}[!] Error: El servicio falló. Revisa 'journalctl -u xray'${NC}"
fi

LINK="trojan://$PASS@$IP:$PORT?security=tls&sni=$BUG&fp=chrome&type=ws&path=/krakervps#KRAKER_TROJAN"
msg_header "TROJAN INSTALADO (PUERTO $PORT)"
echo -e "${GREEN}✔ KRAKER TROJAN COEXISTIENDO CON ÉXITO!${NC}"
echo -e "${YELLOW}Enlace:${NC} $LINK"
echo -e "${BARRA}"

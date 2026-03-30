#!/bin/bash
# KRAKER MASTER - VMess WS + TLS
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Master de VMess
msg_header "VMESS WS + TLS [MASTER SELECTOR]"
echo -e "${YELLOW}[1] > ${WHITE}MODO AUTO (Usar IP del VPS para el Túnel)${NC}"
echo -e "${YELLOW}[2] > ${WHITE}MODO DOMINIO (Usar tu propio Dominio)${NC}"
echo -e "${BARRA}"
read -p "Seleccione modo [1-2]: " VM_MODE

install_deps curl jq openssl coreutils ufw lsof
IP_PUB=$(get_ip)

if [[ "$VM_MODE" == "2" ]]; then
    read -p "Ingresa tu Dominio: " BUG
else
    BUG=$IP_PUB
fi
[[ -z $BUG ]] && BUG=$IP_PUB

# Puerto Detectado (Predeterminado 2083)
PORT=2083
if ss -ntlp | grep -q ":2083 "; then
    PORT=8443
    echo -e "${YELLOW}[!] Puerto 2083 ocupado. Usando alternativo: $PORT${NC}"
fi

# 2. Xray Core Integrity (Master Check)
install_xray() {
    msg_header "VERIFICANDO NÚCLEO XRAY"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando Xray-core oficialmente...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
}

# 3. Datos y Configuración
install_xray
UUID=$(/usr/local/bin/xray uuid)

echo -e "${YELLOW}[*] Generando certificados y configuración VMess para $BUG...${NC}"
mkdir -p /etc/kraker_vmess
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_vmess/server.key -out /etc/kraker_vmess/server.crt -subj "/CN=$BUG" -days 3650 2>/dev/null

# Limpiar puertos en conflicto (Si es puerto 443, pero aquí usamos 2083/8443)
# No necesitamos parar servicios si el puerto está libre.

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

# Inyectar en Configuración Maestra con JQ
if [ ! -f /usr/local/etc/xray/config.json ]; then
    echo "{\"log\": {\"loglevel\": \"warning\"}, \"inbounds\": [], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

jq 'del(.inbounds[] | select(.tag == "VMESS_INBOUND"))' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp
jq --argjson new "$(cat /usr/local/etc/xray/vmess_inbound.json)" '.inbounds += [$new]' /usr/local/etc/xray/config.json.tmp > /usr/local/etc/xray/config.json
rm /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/vmess_inbound.json

# 4. Activación y Verificación
systemctl daemon-reload
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

# 5. Generar Enlace
VMESS_JSON=$(cat << EOM
{ "v": "2", "ps": "KRAKER_VMESS", "add": "$IP_PUB", "port": "$PORT", "id": "$UUID", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$BUG", "path": "/krakervps", "tls": "tls", "sni": "$BUG" }
EOM
)
LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"

msg_header "VMESS INSTALADO CON ÉXITO"
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✔ KRAKER VMESS ACTIVO (PUERTO $PORT)${NC}"
    echo -e "${YELLOW}Enlace:${NC} $LINK"
else
    echo -e "${RED}[!] Error: Xray no inició. Revisa logs.${NC}"
fi
echo -e "${BARRA}"

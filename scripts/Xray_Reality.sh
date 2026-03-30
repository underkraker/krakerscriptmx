#!/bin/bash
# KRAKER MASTER - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "XRAY REALITY SETUP"
install_deps curl jq openssl coreutils ufw lsof

# 2. Maestro Xray y Verificación de Integridad
install_xray() {
    msg_header "MASTER XRAY INSTALLER"
    if [[ ! -s /usr/local/bin/xray ]]; then
        echo -e "${YELLOW}[*] Instalando núcleo oficial de Xray...${NC}"
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    # Verificación de Binario
    if [[ -s /usr/local/bin/xray ]]; then
        echo -e "${GREEN}[✔] Binario Xray Verificado ($(ls -lh /usr/local/bin/xray | awk '{print $5}'))${NC}"
    else
        echo -e "${RED}[!] Error: No se detectó el binario. Instalando estático...${NC}"
        wget -qO /usr/local/bin/xray "https://github.com/underkraker/xray-static/raw/main/xray"
        chmod +x /usr/local/bin/xray
    fi
}

# 3. Datos y Configuración (Política de No-Interrupción)
install_xray
UUID=$(/usr/local/bin/xray uuid)
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
IP_PUB=$(get_ip)

# Automatización Master: Selección de SNI de Alta Fidelidad
echo -e "${YELLOW}[*] Seleccionando SNI Blindado automáticamente...${NC}"
BUG="www.google.com"
echo -e "${GREEN}[✔] SNI Seleccionado: $BUG (Google)${NC}"

# Port Safe Selection (No interrumpir 443 si está en uso)
PORT=443
if ss -ntlp | grep -q ":443 "; then
    PORT=4433
    echo -e "${YELLOW}[!] Puerto 443 en uso por otro servicio. Usando alternativo: $PORT${NC}"
fi
if ss -ntlp | grep -q ":$PORT "; then
    PORT=2083 # Puerto HTTPS Cloudflare común
    echo -e "${YELLOW}[!] Re-intentando puerto: $PORT${NC}"
fi

# Generar Configuración Base (Usando JQ para Inmunidad Vital)
mkdir -p /usr/local/etc/xray
echo "{}" | jq \
    --arg port "$PORT" \
    --arg uuid "$UUID" \
    --arg dest "$BUG:443" \
    --arg sni "$BUG" \
    --arg pbk "$PRIVATE_KEY" \
    --arg sid "$SHORT_ID" \
    '
    .log = {"loglevel": "warning"} |
    .inbounds = [{
        "port": ($port | tonumber), "protocol": "vless", "tag": "REALITY_INBOUND",
        "settings": {"clients": [{"id": $uuid, "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": $dest, "xver": 0,
                "serverNames": [$sni], "privateKey": $pbk, "shortIds": [$sid]
            }
        },
        "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    }] |
    .outbounds = [{"protocol": "freedom"}]
    ' > /usr/local/etc/xray/config.json

# Validar Configuración con Diagnóstico Visible
echo -e "${YELLOW}[*] Validando consistencia del Protocolo...${NC}"
if /usr/local/bin/xray test -c /usr/local/etc/xray/config.json > /dev/null 2>&1; then
    echo -e "${GREEN}[✔] Protocolo Xray Reality Validado.${NC}"
else
    echo -e "${RED}[!] ERROR CRÍTICO: Tu SNI Bug no es válido o faltan herramientas (JQ).${NC}"
    echo -e "${YELLOW}[*] Iniciando AUTO-REPARACIÓN DE EMERGENCIA...${NC}"
    echo -e "${YELLOW}[*] El sistema usará un destino seguro (google) para poder arrancar.${NC}"
    sleep 8
    
    # Auto-Reparación SIN dependencias (Heredoc Directo)
    cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "vless", "tag": "REALITY_REPAIRED",
        "settings": {"clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": "www.google.com:443", "xver": 0,
                "serverNames": ["www.google.com"], "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"]
            }
        },
        "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    echo -e "${GREEN}[✔] Auto-Reparación Completada con Éxito.${NC}"
fi

# 4. Activación Maestro
systemctl daemon-reload
systemctl enable xray > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1
ufw allow $PORT/tcp > /dev/null 2>&1

if systemctl is-active --quiet xray; then
    echo -e "${GREEN}[✔] SERVICIO XRAY CORRIENDO EN PUERTO $PORT${NC}"
else
    echo -e "${RED}[!] Error Fatal: El servicio no inició. Revisa 'journalctl -u xray'${NC}"
fi

LINK="vless://$UUID@$IP_PUB:$PORT?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_REALITY"

msg_header "REALITY INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER REALITY REPARADO Y ACTIVADO!${NC}"
echo -e "${YELLOW}Enlace :${NC} $LINK"
echo -e "${BARRA}"

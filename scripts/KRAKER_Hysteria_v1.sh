#!/bin/bash
# KRAKER MASTER - HYSTERIA v1 SETUP (LEGACY)
# Optimized for Ultra-Speed and Maximum Compatibility

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Master
msg_header "HYSTERIA v1 - MASTER SETUP"
install_deps wget openssl coreutils ufw lsof

IP_PUB=$(get_ip)
BUG=$IP_PUB
echo -e "${YELLOW}[*] Generando SNI de Seguridad Automático: $BUG${NC}"

# Detección Inteligente de Arquitectura (AMD64 / ARM64)
ARCH=$(uname -m)
case $ARCH in
    x86_64) BIN_URL="https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64" ;;
    aarch64) BIN_URL="https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-arm64" ;;
    *) BIN_URL="https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64" ;;
esac

echo -e "${YELLOW}[*] Descargando Hysteria v1 (Legacy) para $ARCH...${NC}"
wget -qO /usr/local/bin/hysteria-v1 "$BIN_URL"
chmod +x /usr/local/bin/hysteria-v1

# 2. UDP Boost (Kernel Tuning)
echo -e "${YELLOW}[*] Inyectando UDP Boost al Kernel...${NC}"
sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1
sysctl -p > /dev/null 2>&1

# 3. Certificados y Configuración JSON (V1 es JSON)
mkdir -p /etc/hysteria_v1
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria_v1/server.key -out /etc/hysteria_v1/server.crt -subj "/CN=$BUG" -days 3650 2>/dev/null

PASS=$(openssl rand -hex 8)

cat << EOF > /etc/hysteria_v1/config.json
{
  "listen": ":4433",
  "cert": "/etc/hysteria_v1/server.crt",
  "key": "/etc/hysteria_v1/server.key",
  "auth": {
    "mode": "password",
    "config": {
      "password": "$PASS"
    }
  },
  "masquerade": "https://www.google.com/"
}
EOF

# 4. Servicio Systemd
cat << EOF > /etc/systemd/system/hysteria-v1.service
[Unit]
Description=KRAKER MASTER - Hysteria v1 [UDP Boosted]
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria-v1 server -c /etc/hysteria_v1/config.json
Restart=always
User=root
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-v1 > /dev/null 2>&1
systemctl restart hysteria-v1 > /dev/null 2>&1
ufw allow 4433/udp > /dev/null 2>&1

# 5. Verificación Final
if systemctl is-active --quiet hysteria-v1; then
    msg_header "HYSTERIA V1 - MASTER READY"
    echo -e "${GREEN}✔ SERVICIO HYSTERIA v1 ACTIVO (PUERTO 4433 UDP)${NC}"
    echo -e "${YELLOW}Enlace :${NC} hysteria://$IP_PUB:4433/?auth=$PASS&insecure=1&sni=$BUG#KRAKER_HY1"
else
    echo -e "${RED}[!] Error: Hysteria v1 falló al iniciar. Revisa puertos ocupados.${NC}"
fi
echo -e "${BARRA}"

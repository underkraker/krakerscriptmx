#!/bin/bash
# KRAKER MASTER - HYSTERIA v2 SETUP
# Optimized for Ultra-Speed and Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración de Reparación Quirúrgica
msg_header "HYSTERIA v2 - REPARACIÓN EXCLUSIVA"
install_deps wget openssl coreutils ufw lsof

# 3. Detección de Arquitectura y SNI Automático
msg_header "HYSTERIA v2 - MASTER OPTIMIZER"
IP_PUB=$(get_ip)
BUG=$IP_PUB
echo -e "${YELLOW}[*] Generando SNI Automático: $BUG${NC}"

# Detección Inteligente de Arquitectura (AMD64 / ARM64)
ARCH=$(uname -m)
case $ARCH in
    x86_64) BIN_URL="https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64" ;;
    aarch64) BIN_URL="https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-arm64" ;;
    *) BIN_URL="https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64" ;;
esac

echo -e "${YELLOW}[*] Descargando Hysteria v2 para arquitectura $ARCH...${NC}"
wget -qO /usr/local/bin/hysteria "$BIN_URL"
chmod +x /usr/local/bin/hysteria

# 4. UDP Boost (Optimización de Kernel para Gaming/Streaming)
echo -e "${YELLOW}[*] Inyectando UDP Boost al Kernel...${NC}"
sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1
sysctl -p > /dev/null 2>&1

# 5. Certificado y Configuración YAML
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=$BUG" -days 3650 2>/dev/null

PASS=$(openssl rand -hex 8)

cat << EOF > /etc/hysteria/config.yaml
listen: :443
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $PASS
masquerade:
  type: proxy
  proxy:
    url: https://www.google.com/
EOF

# 6. Activación Maestra con Systemd
cat << EOF > /etc/systemd/system/hysteria-server.service
[Unit]
Description=KRAKER MASTER - Hysteria v2 [UDP Boosted]
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
User=root
# Optimización de límites de archivos
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-server > /dev/null 2>&1
systemctl restart hysteria-server > /dev/null 2>&1
ufw allow 443/udp > /dev/null 2>&1

# BLOQUE DE VERIFICACIÓN FINAL
if systemctl is-active --quiet hysteria-server; then
    msg_header "HYSTERIA V2 - MASTER READY"
    echo -e "${GREEN}✔ SERVICIO HYSTERIA ACTIVO Y CORRIENDO (UDP BOOST)${NC}"
    echo -e "${YELLOW}Enlace :${NC} hysteria2://$PASS@$IP_PUB:443/?insecure=1&sni=$BUG#KRAKER_HY2"
else
    echo -e "${RED}[!] Error: Hysteria falló al iniciar. Revisa 'journalctl -u hysteria-server'${NC}"
fi
echo -e "${BARRA}"

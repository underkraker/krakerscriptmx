#!/bin/bash
# KRAKER MASTER - HYSTERIA v2 SETUP
# Optimized for Ultra-Speed and Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración de Reparación Quirúrgica
msg_header "HYSTERIA v2 - REPARACIÓN EXCLUSIVA"
install_deps wget openssl coreutils ufw lsof

read -p "Ingresa el SNI Bug para Hysteria: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

# 2. Instalación Manual del Binario (GitHub Directo)
echo -e "${YELLOW}[*] Descargando Binario Hysteria v2 directamente de GitHub...${NC}"
# Forzar DNS 8.8.8.8 por si SlowDNS bloqueó la resolución
grep -q "8.8.8.8" /etc/resolv.conf || echo "nameserver 8.8.8.8" >> /etc/resolv.conf

wget -qO /usr/local/bin/hysteria "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64"
chmod +x /usr/local/bin/hysteria

# Verificación Instantánea de Binario
if [[ -s /usr/local/bin/hysteria ]]; then
    echo -e "${GREEN}[✔] Binario Hysteria Verificado: $(/usr/local/bin/hysteria version | head -n 1)${NC}"
else
    echo -e "${RED}[!] Error Fatal: No se pudo descargar el binario de Hysteria. Revisa el internet de la VPS.${NC}"
    exit 1
fi

# 3. Certificado y Configuración YAML
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

PASS=$(openssl rand -hex 8)
IP=$(get_ip)

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
    url: https://$BUG/
EOF

# 4. Creación de Servicio Systemd Dedicado
echo -e "${YELLOW}[*] Configurando Servicio Systemd de Élite...${NC}"
cat << EOF > /etc/systemd/system/hysteria-server.service
[Unit]
Description=KRAKER MASTER - Hysteria v2 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-server > /dev/null 2>&1
systemctl restart hysteria-server > /dev/null 2>&1
ufw allow 443/udp > /dev/null 2>&1

# 5. BLOQUE DE VERIFICACIÓN FINAL
echo -e "${BARRA}"
if systemctl is-active --quiet hysteria-server; then
    echo -e "${GREEN}[✔] SERVICIO HYSTERIA ACTIVO Y CORRIENDO${NC}"
    echo -e "${GREEN}[✔] PUERTO 443 UDP ABIERTO${NC}"
else
    echo -e "${RED}[!] Error: Hysteria falló al iniciar. Revisa 'journalctl -u hysteria-server'${NC}"
fi
echo -e "${BARRA}"

msg_header "HYSTERIA V2 ACTIVADO"
echo -e "${YELLOW}Enlace :${NC} hysteria2://$PASS@$IP:443/?insecure=1&sni=$BUG#KRAKER_HY2"
echo -e "${BARRA}"

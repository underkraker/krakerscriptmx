#!/bin/bash
# KRAKER MASTER - HYSTERIA v2 SETUP
# Optimized for Ultra-Speed and Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Configuración Inicial
msg_header "HYSTERIA v2 SETUP"
install_deps curl openssl coreutils ufw lsof

read -p "Ingresa el SNI Bug para Hysteria: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

# 2. Hysteria Installation (Expert Mode)
echo -e "${YELLOW}[*] Instalando Hysteria v2 core...${NC}"
# Forzar DNS temporal para la descarga por si acaso
echo "nameserver 8.8.8.8" > /etc/resolv.conf

if [[ ! -s /usr/local/bin/hysteria ]]; then
    bash <(curl -fsSL https://get.hy2.biz) --check > /dev/null 2>&1
fi

# Generar Certificado
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# Password Aleatoria e IP
PASS=$(openssl rand -hex 8)
IP=$(get_ip)

# 4. Configuration (YAML)
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

# 4. Service & Firewall
setup_motd
ufw allow 443/udp > /dev/null 2>&1
systemctl daemon-reload
systemctl enable hysteria-server.service > /dev/null 2>&1
systemctl restart hysteria-server.service > /dev/null 2>&1

msg_header "HYSTERIA V2 ACTIVADO"
echo -e "${GREEN}✔ KRAKER HYSTERIA v2 [PORT: 443 UDP] ACTIVADO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}IP       :${NC} $IP"
echo -e "${YELLOW}Puerto   :${NC} 443 (UDP)"
echo -e "${YELLOW}Password :${NC} $PASS"
echo -e "${YELLOW}SNI Bug  :${NC} $BUG"
echo -e "${BARRA}"
echo -e "${CYAN}Link Hysteria:${NC}"
echo -e "hysteria2://$PASS@$IP:443/?insecure=1&sni=$BUG#KRAKER_HY2"
echo -e "${BARRA}"

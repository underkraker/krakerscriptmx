#!/bin/bash
# KRAKER MASTER - HYSTERIA v2 SETUP
# Optimized for Ultra-Speed and Gaming

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Install Dependencies
msg_header "HYSTERIA v2 SETUP"
install_deps curl openssl coreutils ufw lsof

# 2. Hysteria Installation
echo -e "${YELLOW}[*] Instalando Hysteria v2 core...${NC}"
bash <(curl -fsSL https://get.hy2.biz) > /dev/null 2>&1

# 3. Config & Certs
echo -e "${CYAN}Ingresa el SNI Bug para Hysteria (ej: cdn-global.configcat.com)${NC}"
read -p "SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

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

# Service & Firewall
setup_motd
ufw allow 443/udp > /dev/null 2>&1
systemctl enable hysteria-server.service > /dev/null 2>&1
systemctl restart hysteria-server.service > /dev/null 2>&1

msg_header "HYSTERIA INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER HYSTERIA v2 INSTALADO CON ÉXITO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}DATOS DE CONEXIÓN:${NC}"
echo -e "${CYAN}IP       :${NC} $IP"
echo -e "${CYAN}Puerto   :${NC} 443 (UDP)"
echo -e "${CYAN}Password :${NC} $PASS"
echo -e "${CYAN}SNI Bug  :${NC} $BUG"
echo -e "${BARRA}"
echo -e "${GREEN}RECUERDA: Hysteria usa UDP para máxima velocidad.${NC}"
echo -e "${BARRA}"

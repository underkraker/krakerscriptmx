#!/bin/bash
# KRAKER MASTER - SLOWDNS (DNSTT)
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Instalar Dependencias y DNSTT
install_dnstt() {
    echo -e "${YELLOW}[1/4] Instalando Dependencias y DNSTT Server...${NC}"
    install_deps curl wget iptables ufw coreutils
    
    if [[ ! -f /usr/bin/dnstt-server ]]; then
        wget -O /usr/bin/dnstt-server "https://github.com/google/dnstt/releases/download/v20220210/dnstt-server-linux-amd64" > /dev/null 2>&1
        chmod +x /usr/bin/dnstt-server
    fi
}

# 2. Generar Llaves
generate_keys() {
    echo -e "${YELLOW}[2/4] Generando Llaves KRAKER DNS...${NC}"
    mkdir -p /etc/kraker_dns
    /usr/bin/dnstt-server -gen-key -pub /etc/kraker_dns/server.pub -priv /etc/kraker_dns/server.key > /dev/null 2>&1
    PUB_KEY=$(cat /etc/kraker_dns/server.pub)
}

# 3. Configurar Firewall
setup_network() {
    echo -e "${YELLOW}[3/4] Configurando Puerto 53 UDP (SlowDNS)...${NC}"
    systemctl stop systemd-resolved > /dev/null 2>&1
    systemctl disable systemd-resolved > /dev/null 2>&1
    iptables -I INPUT -p udp --dport 53 -j ACCEPT
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
}

# 4. Crear Servicio
create_service() {
    msg_header "ACTIVANDO KRAKER-DNS"
    cat << EOF > /etc/systemd/system/kraker-dns.service
[Unit]
Description=KRAKER MASTER - SlowDNS
After=network.target

[Service]
ExecStart=/usr/bin/dnstt-server -udp :5300 -pub /etc/kraker_dns/server.pub -key /etc/kraker_dns/server.key -tunnel 127.0.0.1:80
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kraker-dns > /dev/null 2>&1
    systemctl restart kraker-dns > /dev/null 2>&1
}

msg_header "EXTREME SLOWDNS ACTIVATION"
setup_motd
install_dnstt
generate_keys
setup_network
create_service

echo -e "${GREEN}✔ KRAKER DNS (SlowDNS) ACTIVADO!${NC}"
echo -e "${YELLOW}Public Key:${NC} $PUB_KEY"
echo -e "${BARRA}"
echo -e "${CYAN}Nota: Recuerda configurar los NS records en tu dominio.${NC}"
echo -e "${BARRA}"

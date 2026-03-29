#!/bin/bash
# KRAKER MASTER - UDP GAMING (BadVPN)
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Optimización Kernel BBR
tune_network() {
    echo -e "${YELLOW}[1/3] Aplicando BBR y Tunings de Gaming...${NC}"
    if ! sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi
    sysctl -p > /dev/null 2>&1
}

# 2. Instalación BadVPN
install_badvpn() {
    echo -e "${YELLOW}[2/3] Instalando BadVPN udpgw...${NC}"
    if [[ ! -f /usr/bin/badvpn-udpgw ]]; then
        wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-linux-x86_64" > /dev/null 2>&1
        chmod +x /usr/bin/badvpn-udpgw
    fi
}

# 3. Servicio Systemd
create_service() {
    echo -e "${YELLOW}[3/3] Iniciando Sistema de Prioridad Alta...${NC}"
    cat << 'EOF' > /etc/systemd/system/kraker-udp.service
[Unit]
Description=KRAKER MASTER - UDP Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:7100 --max-clients 500 --listen-addr 0.0.0.0:7200 --max-clients 500 --listen-addr 0.0.0.0:7300 --max-clients 500
Restart=always
Nice=-20
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kraker-udp > /dev/null 2>&1
    systemctl restart kraker-udp > /dev/null 2>&1
}

msg_header "UDP GAMING OPTIMIZER"
install_deps wget coreutils
setup_motd
tune_network
install_badvpn
create_service

echo -e "${GREEN}✔ KRAKER UDP GAMING ACTIVADO!${NC}"
echo -e "${CYAN}Puertos: 7100, 7200, 7300${NC}"
echo -e "${BARRA}"

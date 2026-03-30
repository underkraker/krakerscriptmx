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

# 2. Instalación BadVPN (Compilación Profesional v2)
install_badvpn() {
    msg_header "INSTALANDO BADVPN UDPGW"
    if [[ -f /usr/bin/badvpn-udpgw ]]; then
        echo -e "${GREEN}[✔] BadVPN ya está instalado.${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Preparando dependencias Ubuntu 24.04...${NC}"
    apt update -y > /dev/null 2>&1
    apt install -y cmake build-essential wget tar libssl-dev pkg-config > /dev/null 2>&1

    echo -e "${YELLOW}[*] Descargando y compilando desde código fuente (Parcheado)...${NC}"
    rm -rf /tmp/badvpn-1.999.130
    cd /tmp
    wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz > /dev/null 2>&1
    tar xvzf 1.999.130.tar.gz > /dev/null 2>&1
    cd badvpn-1.999.130
    mkdir build && cd build
    
    # Parche: -Wno-error para evitar fallos de compilación en Ubuntu 24.04
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 \
             -DCMAKE_C_FLAGS="-Wno-error" -DCMAKE_CXX_FLAGS="-Wno-error" > /dev/null 2>&1
    
    make install > /dev/null 2>&1
    
    if [[ -f /usr/local/bin/badvpn-udpgw ]]; then
        ln -sf /usr/local/bin/badvpn-udpgw /usr/bin/badvpn-udpgw
        echo -e "${GREEN}[✔] BadVPN compilado con éxito.${NC}"
    else
        echo -e "${RED}[!] Error grave en la compilación. Usando binario estático de emergencia...${NC}"
        wget -q -O /usr/bin/badvpn-udpgw "https://github.com/itxtutor/badvpn/raw/master/badvpn-udpgw-x86_64"
        chmod +x /usr/bin/badvpn-udpgw
    fi
}

# 3. Servicio Systemd Elite v2
create_service() {
    msg_header "CONFIGURACIÓN DE SERVICIO UDP"
    echo -e "${YELLOW}[*] Creando KRAKER UDP Service...${NC}"
    cat << 'EOF' > /etc/systemd/system/kraker-udp.service
[Unit]
Description=KRAKER MASTER - UDP Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:7100 --max-clients 500 --listen-addr 0.0.0.0:7200 --max-clients 500 --listen-addr 0.0.0.0:7300 --max-clients 500
Restart=always
RestartSec=3
StandardOutput=append:/var/log/kraker-udp.log
StandardError=append:/var/log/kraker-udp.log
LimitNOFILE=65535
Nice=-20
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kraker-udp > /dev/null 2>&1
    systemctl restart kraker-udp > /dev/null 2>&1

    # Verificación Crítica
    sleep 3
    if ! systemctl is-active --quiet kraker-udp; then
        echo -e "${RED}[!] ¡FALLO CRÍTICO! El servicio no arrancó. Revisando logs...${NC}"
        tail -n 10 /var/log/kraker-udp.log
    fi

    # Abrir Puertos (Opcional - Firewall Detect)
    if command -v ufw &> /dev/null; then
        ufw allow 7100:7300/udp > /dev/null 2>&1
        ufw allow 7100:7300/tcp > /dev/null 2>&1
    fi
}

msg_header "UDP GAMING OPTIMIZER"
setup_motd
tune_network
install_badvpn
create_service

echo -e "${GREEN}✔ KRAKER UDP GAMING ACTIVADO EXPOSIVAMENTE!${NC}"
echo -e "${CYAN}Puertos: 7100 (Bajo), 7200 (Medio), 7300 (Alto)${NC}"
echo -e "${BARRA}"

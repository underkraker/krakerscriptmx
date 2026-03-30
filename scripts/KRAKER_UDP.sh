#!/bin/bash
# KRAKER MASTER - UDP GAMING (BadVPN)
# Versión Auditada y Estandarizada

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Optimización Kernel Turbo Gaming
tune_network() {
    msg_header "CARGANDO MÓDULOS DE BAJA LATENCIA"
    echo -e "${YELLOW}[*] Optimizando Stack de Red para Ping Mínimo...${NC}"
    
    cat << 'EOF' > /etc/sysctl.d/99-kraker-gaming.conf
# Priorizar velocidad sobre rendimiento total
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_fin_timeout = 15

# Programador de paquetes para evitar Bufferbloat (Lag)
net.core.default_qdisc = fq_codel

# Buffers de red optimizados para Gaming UDP
net.core.rmem_default = 524288
net.core.rmem_max = 2097152
net.core.wmem_default = 524288
net.core.wmem_max = 2097152
EOF
    sysctl --system > /dev/null 2>&1
    echo -e "${GREEN}[✔] Kernel Tuneado para Gaming v4.0 con éxito.${NC}"
}

# 2. Instalación BadVPN (MODO EXPERTO - ULTRA ROBUSTO)
install_badvpn() {
    msg_header "INSTALANDO BADVPN UDPGW"
    
    # Limpieza de instalaciones fallidas (archivos de 0 bytes)
    if [[ -f /usr/bin/badvpn-udpgw && ! -s /usr/bin/badvpn-udpgw ]]; then
        echo -e "${YELLOW}[!] Detectado binario corrupto (0 bytes). Limpiando...${NC}"
        rm -f /usr/bin/badvpn-udpgw
    fi

    if [[ -s /usr/bin/badvpn-udpgw ]]; then
        echo -e "${GREEN}[✔] BadVPN ya está instalado y verificado.${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Instalando dependencias necesarias...${NC}"
    apt update -y
    apt install -y cmake build-essential wget tar libssl-dev pkg-config

    echo -e "${YELLOW}[*] Intentando Compilación Directa (Garantiza Compatibilidad)...${NC}"
    rm -rf /tmp/badvpn-1.999.130
    cd /tmp
    if wget https://github.com/ambrop72/badvpn/archive/1.999.130.tar.gz; then
        tar xvzf 1.999.130.tar.gz
        cd badvpn-1.999.130
        mkdir build && cd build
        # Parche de compatibilidad extrema para Ubuntu 24.04
        cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 \
                 -DCMAKE_C_FLAGS="-Wno-error" -DCMAKE_CXX_FLAGS="-Wno-error"
        make install
        
        if [[ -s /usr/local/bin/badvpn-udpgw ]]; then
            ln -sf /usr/local/bin/badvpn-udpgw /usr/bin/badvpn-udpgw
            echo -e "${GREEN}[✔] BadVPN compilado con éxito.${NC}"
            return
        fi
    fi

    echo -e "${RED}[!] Falló la compilación. Usando Binario Estático de Emergencia...${NC}"
    # Fuente de alta disponibilidad para binarios estáticos
    wget -O /usr/bin/badvpn-udpgw "https://github.com/itxtutor/badvpn/raw/master/badvpn-udpgw-x86_64"
    chmod +x /usr/bin/badvpn-udpgw
    
    if [[ ! -s /usr/bin/badvpn-udpgw ]]; then
        echo -e "${RED}[!!!] ERROR CRÍTICO: No se pudo obtener un binario válido.${NC}"
        exit 1
    fi
}

# 3. Servicio Systemd Elite v3 (Auditado)
create_service() {
    msg_header "ACTIVANDO SERVICIO UDP MASTER"
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
    systemctl enable kraker-udp
    systemctl restart kraker-udp

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

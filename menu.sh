#!/bin/bash
# KRAKER MASTER - Management Panel
# Optimized for VPS - Elite Dashboard
# Powered by KRAKER VPS

# Cargar Librería de Utilidades
SOURCE_PATH=$(readlink -f "$0")
SOURCE_DIR=$(dirname "$SOURCE_PATH")
[[ -f "$SOURCE_DIR/scripts/utils.sh" ]] && source "$SOURCE_DIR/scripts/utils.sh" || { echo "Error: utils.sh no encontrado."; exit 1; }

# Monitor de Sistema Real-Time
sys_stats() {
    IP_EXT=$(get_ip)
    OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2 || echo "Linux VPS")
    RAM_USED=$(free -m | awk '/Mem:/ { print $3 }')
    RAM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')"%"
    UPTIME=$(uptime -p)
    ACTIVE_PORTS=$(get_active_ports)

    echo -e "  ${WHITE}DIRECCIÓN IP   : ${GREEN}$IP_EXT${NC}          ${WHITE}UPTIME : ${GREEN}$UPTIME${NC}"
    echo -e "  ${WHITE}SISTEMA OP.    : ${GREEN}$OS${NC}"
    echo -e "  ${WHITE}USO DE MEMORIA : ${GREEN}$RAM_USED MB / $RAM_TOTAL MB${NC}          ${WHITE}CPU : ${GREEN}$CPU_USAGE${NC}"
    echo -e "  ${WHITE}PUERTOS ACTIVOS: ${CYAN}${ACTIVE_PORTS:-NINGUNO}${NC}"
    echo -e "${BARRA}"
}

# Menu Principal
main_menu() {
    msg_banner
    sys_stats
    echo -e "  ${YELLOW}[01]${NC} ${WHITE}XRAY REALITY (VLESS)${NC}       ${YELLOW}[06]${NC} ${WHITE}TROJAN (XRAY)${NC}"
    echo -e "  ${YELLOW}[02]${NC} ${WHITE}HYSTERIA V2 (UDP)${NC}          ${YELLOW}[07]${NC} ${WHITE}SHADOWSOCKS${NC}"
    echo -e "  ${YELLOW}[03]${NC} ${WHITE}VPN SSL (STUNNEL)${NC}          ${YELLOW}[08]${NC} ${WHITE}UDP GAMING (HIGH SPEED)${NC}"
    echo -e "  ${YELLOW}[04]${NC} ${WHITE}SSL GATEWAY (PYTHON)${NC}       ${YELLOW}[09]${NC} ${WHITE}KRAKER DNS SECURITY${NC}"
    echo -e "  ${YELLOW}[05]${NC} ${WHITE}VMESS (XRAY)${NC}               ${YELLOW}[10]${NC} ${WHITE}DROPBEAR MANAGER${NC}"
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[11]${NC} ${WHITE}ESTADO DE SERVICIOS${NC}        ${YELLOW}[12]${NC} ${WHITE}TEST DE VELOCIDAD${NC}"
    echo -e "  ${YELLOW}[13]${NC} ${WHITE}GESTIÓN DE USUARIOS${NC}        ${YELLOW}[00]${NC} ${RED}SALIR DEL MENU${NC}"
    echo -e "${BARRA}"
    echo -en "  ${CYAN}SELECCIONE UNA OPCIÓN: ${NC}"
    read opt

    case $opt in
        1|01) bash "$SOURCE_DIR/scripts/Xray_Reality.sh" ;;
        2|02) bash "$SOURCE_DIR/scripts/Hysteria_v2.sh" ;;
        3|03) bash "$SOURCE_DIR/scripts/KRAKER_SSL.sh" ;;
        4|04) python3 "$SOURCE_DIR/scripts/KRAKER_SSL_Gateway.py" ;;
        5|05) bash "$SOURCE_DIR/scripts/KRAKER_VMess.sh" ;;
        6|06) bash "$SOURCE_DIR/scripts/KRAKER_Trojan.sh" ;;
        7|07) bash "$SOURCE_DIR/scripts/KRAKER_Shadowsocks.sh" ;;
        8|08) bash "$SOURCE_DIR/scripts/KRAKER_UDP.sh" ;;
        9|09) bash "$SOURCE_DIR/scripts/KRAKER_DNS.sh" ;;
        10) bash "$SOURCE_DIR/scripts/KRAKER_Dropbear.sh" ;;
        11) 
            msg_header "ESTADO DE SERVICIOS"
            lsof -i -P -n | grep LISTEN || echo -e "${RED}No hay servicios escuchando.${NC}"
            ;;
        12) 
            echo -e "${YELLOW}Ejecutando Test de Velocidad...${NC}"
            install_deps speedtest-cli
            speedtest-cli
            ;;
        13)
            install_deps jq
            bash "$SOURCE_DIR/scripts/KRAKER_User.sh"
            ;;
        0|00) 
            clear
            echo -e "${GREEN}Gracias por usar KRAKER MASTER PANEL!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Opción inválida!${NC}" 
            sleep 1 
            ;;
    esac
}

# Configuración Inicial (Permisos y Requisitos)
check_root
chmod +x "$SOURCE_DIR/scripts"/*.sh 2>/dev/null
chmod +x "$SOURCE_DIR/menu.sh"

# Bucle Infinito
while true; do
    main_menu
    echo -e "\n${YELLOW}Presione ENTER para volver al menú...${NC}"
    read
done

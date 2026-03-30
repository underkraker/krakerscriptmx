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
    
    # Cálculos de Recursos
    RAM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
    RAM_USED=$(free -m | awk '/Mem:/ { print $3 }')
    RAM_PERC=$(( RAM_USED * 100 / RAM_TOTAL ))
    
    # Optimización Master: Usar loadavg (Ultra Ligero) en lugar de top
    CPU_USAGE=$(awk '{print $1 * 100 / 4}' /proc/loadavg | cut -d. -f1) # Basado en 4 núcleos (Promedio)
    # Si quieres una lectura exacta por núcleos detectados:
    CPUS=$(grep -c ^processor /proc/cpuinfo)
    CPU_USAGE=$(awk -v c="$CPUS" '{print ($1/c)*100}' /proc/loadavg | cut -d. -f1)
    [[ -z $CPU_USAGE ]] && CPU_USAGE=0

    UPTIME=$(uptime -p)
    ACTIVE_PORTS=$(get_active_ports)

    echo -e "  ${WHITE}IP PÚBLICA    : ${GREEN}$IP_EXT${NC}          ${WHITE}SISTEMA : ${GREEN}$OS${NC}"
    echo -e "  ${WHITE}UPTIME        : ${GREEN}$UPTIME${NC}"
    echo -e "  ${WHITE}MEMORIA RAM   : $(get_resource_bar $RAM_PERC) ${WHITE}($RAM_USED / $RAM_TOTAL MB)${NC}"
    echo -e "  ${WHITE}CARGA CPU     : $(get_resource_bar $CPU_USAGE)${NC}"
    echo -e "  ${WHITE}PUERTOS ACTIVOS: ${CYAN}${ACTIVE_PORTS:-NINGUNO}${NC}"
    echo -e "${BARRA}"
}

# Menu Principal
main_menu() {
    msg_banner
    IP_EXT=$(get_ip)
    OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2 || echo "Linux VPS")
    UPTIME=$(uptime -p)
    CPU_USAGE=$(awk -v c="$(grep -c ^processor /proc/cpuinfo)" '{print ($1/c)*100}' /proc/loadavg | cut -d. -f1)
    RAM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
    RAM_USED=$(free -m | awk '/Mem:/ { print $3 }')
    RAM_PERC=$(( RAM_USED * 100 / RAM_TOTAL ))

    echo -e "${B_TOP}"
    echo -e "  ${WHITE}SISTEMA: ${GREEN}$OS${NC}"
    echo -e "  ${WHITE}IP PUB : ${CYAN}$IP_EXT${NC}   ${WHITE}UPTIME: ${GREEN}$UPTIME${NC}"
    echo -e "  ${WHITE}CPU    : $(get_resource_bar $CPU_USAGE)   ${WHITE}RAM: $(get_resource_bar $RAM_PERC)${NC}"
    echo -e "${B_SEP}"
    echo -e "  ${ICON_XRAY} ${CYAN}══ PROTOS XRAY (TCP/WS) ══${NC}      ${ICON_V2} ${MAGENTA}══ UDP & TUNNELS ══${NC}"
    echo -e "  $(get_status 443) ${GRAY}[01]${NC} Xray Reality       $(get_status 443) ${GRAY}[02]${NC} Hysteria v1/v2"
    echo -e "  $(get_status 2083) ${GRAY}[05]${NC} VMess WS+TLS       $(get_status 442) ${GRAY}[03]${NC} VPN SSL (Stunnel)"
    echo -e "  $(get_status 2053) ${GRAY}[06]${NC} Trojan WS+TLS      $(get_status 443) ${GRAY}[04]${NC} SSL Gateway (Py)"
    echo -e "  $(get_status 2096) ${GRAY}[07]${NC} Shadowsocks WS     $(get_status 7100) ${GRAY}[08]${NC} UDP Gaming"
    echo -e "${B_SEP}"
    echo -e "  ${ICON_SYS} ${YELLOW}══ GESTIÓN Y SISTEMA ══${NC}"
    echo -e "  ${GRAY}[11]${NC} Mantenimiento       ${GRAY}[12]${NC} Gestión de Usuarios"
    echo -e "  ${GRAY}[13]${NC} Test de Velocidad   ${GRAY}[14]${NC} Gestor de Servicios"
    echo -e "  ${GRAY}[09]${NC} DNS Security        ${GRAY}[10]${NC} Dropbear Manager"
    echo -e "${B_SEP}"
    echo -e "                 ${RED}[00] SALIR DEL PANEL DE CONTROL${NC}"
    echo -e "${B_BOT}"
    echo -en "  ${CYAN}SELECCIONE UNA OPCIÓN: ${NC}"
    read opt

    case $opt in
        1|01) bash "$SOURCE_DIR/scripts/Xray_Reality.sh" ;;
        2|02) bash "$SOURCE_DIR/scripts/Hysteria_v2.sh" ;;
        3|03) bash "$SOURCE_DIR/scripts/KRAKER_SSL.sh" ;;
        4|04) bash "$SOURCE_DIR/scripts/KRAKER_SSL.sh" ;;
        5|05) bash "$SOURCE_DIR/scripts/KRAKER_VMess.sh" ;;
        6|06) bash "$SOURCE_DIR/scripts/KRAKER_Trojan.sh" ;;
        7|07) bash "$SOURCE_DIR/scripts/KRAKER_Shadowsocks.sh" ;;
        8|08) bash "$SOURCE_DIR/scripts/KRAKER_UDP.sh" ;;
        9|09) bash "$SOURCE_DIR/scripts/KRAKER_DNS.sh" ;;
        10) bash "$SOURCE_DIR/scripts/KRAKER_Dropbear.sh" ;;
        11) bash "$SOURCE_DIR/scripts/KRAKER_System.sh" ;;
        12) bash "$SOURCE_DIR/scripts/KRAKER_User.sh" ;;
        13) 
            echo -e "${YELLOW}Ejecutando Test...${NC}"
            install_deps speedtest-cli
            speedtest-cli
            ;;
        14) bash "$SOURCE_DIR/scripts/KRAKER_Services.sh" ;;
        0|00) clear; echo -e "${GREEN}¡Hasta pronto!${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción inválida!${NC}"; sleep 1 ;;
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

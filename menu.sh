#!/bin/bash
# KRAKER MASTER - Management Panel
# Optimized for VPS - Elite Dashboard
# Powered by KRAKER VPS

# Cargar Librería de Utilidades
SOURCE_PATH=$(readlink -f "$0")
SOURCE_DIR=$(dirname "$SOURCE_PATH")
[[ -f "$SOURCE_DIR/scripts/utils.sh" ]] && source "$SOURCE_DIR/scripts/utils.sh" || { echo "Error: utils.sh no encontrado."; exit 1; }

# Manejo de Argumentos (Auto-Mantenimiento Master)
if [[ "$1" == "--ram-clean" ]]; then
    clean_vps_ram
    exit 0
elif [[ "$1" == "--cpu-clean" ]]; then
    purge_ghost_sessions
    exit 0
fi

# Menu Principal
main_menu() {
    local IP=$1
    local OS_SYS=$2
    msg_banner
    
    # Recursos (Una sola lectura por refresco)
    CPUS=$(grep -c ^processor /proc/cpuinfo)
    UPTIME=$(uptime -p)
    CPU_USAGE=$(awk -v c="$CPUS" '{print ($1/c)*100}' /proc/loadavg | cut -d. -f1)
    MEM_STATS=($(free -m | awk '/Mem:/ { print $2, $3 }'))
    RAM_TOTAL=${MEM_STATS[0]}
    RAM_USED=${MEM_STATS[1]}
    RAM_PERC=$(( RAM_USED * 100 / RAM_TOTAL ))
    USERS=$(get_active_users)

    echo -e "${B_TOP}"
    echo -e "  ${WHITE}SISTEMA: ${GREEN}$OS_SYS${NC}   ${WHITE}USERS: ${GREEN}$USERS${NC}"
    echo -e "  ${WHITE}IP PUB : ${CYAN}$IP${NC}   ${WHITE}UPTIME: ${GREEN}$UPTIME${NC}"
    echo -e "  ${WHITE}CPU    : $(get_resource_bar $CPU_USAGE)   ${WHITE}RAM: $(get_resource_bar $RAM_PERC)${NC}"
    echo -e "${B_SEP}"
    echo -e "  ${ICON_XRAY} ${CYAN}══ PROTOS XRAY (TCP/WS) ══${NC}      ${ICON_V2} ${MAGENTA}══ UDP & TUNNELS ══${NC}"
    echo -e "  $(get_status 443) ${GRAY}[01]${NC} Xray Reality       $(get_status 443) ${GRAY}[02]${NC} Hysteria v1/v2"
    echo -e "  $(get_status 2083) ${GRAY}[05]${NC} VMess WS+TLS       $(get_status 442) ${GRAY}[03]${NC} VPN SSL (Stunnel)"
    echo -e "  $(get_status 2053) ${GRAY}[06]${NC} Trojan WS+TLS      $(get_status 443) ${GRAY}[04]${NC} SSL Gateway (Py)"
    echo -e "  $(get_status 2096) ${GRAY}[07]${NC} Shadowsocks WS     $(get_status 7100) ${GRAY}[08]${NC} UDP Gaming"
    echo -e "${B_SEP}"
    echo -e "  ${ICON_SYS} ${YELLOW}══ GESTIÓN Y SISTEMA ══${NC}"
    echo -e "  ${GRAY}[11]${NC} Mantenimiento (RAM) ${GRAY}[12]${NC} Gestión de Usuarios"
    echo -e "  ${GRAY}[13]${NC} Test de Velocidad   ${GRAY}[14]${NC} Gestor de Servicios"
    echo -e "  ${GRAY}[09]${NC} DNS Security        ${GRAY}[10]${NC} Dropbear Manager"
    echo -e "  ${GRAY}[15]${NC} Banner De La App ✍️"
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
        11) 
            echo -e "${YELLOW}[*] Liberando Memoria RAM y Limpiando Caché Master...${NC}"
            clean_vps_ram
            sleep 2
            echo -e "${GREEN}✔ VPS Optimizada Corectamente.${NC}"
            sleep 1
            ;;
        12) bash "$SOURCE_DIR/scripts/KRAKER_User.sh" ;;
        13) 
            echo -e "${YELLOW}Ejecutando Test...${NC}"
            install_deps speedtest-cli
            speedtest-cli
            ;;
        14) bash "$SOURCE_DIR/scripts/KRAKER_Services.sh" ;;
        15) update_client_message ;;
        0|00) clear; echo -e "${GREEN}¡Hasta pronto!${NC}"; exit 0 ;;
        *) echo -e "${RED}Opción inválida!${NC}"; sleep 1 ;;
    esac
}

# Configuración Inicial y Auto-Mantenimiento
check_root
setup_auto_clean
setup_kraker_banner

# 🛰️ Detección Maestro Única (Aceleración de Inicio)
IP_EXT=$(get_ip)
OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2 || echo "Linux VPS")
chmod +x "$SOURCE_DIR/scripts"/*.sh 2>/dev/null
chmod +x "$SOURCE_DIR/menu.sh"

# Bucle Principal
while true; do
    main_menu "$IP_EXT" "$OS"
    echo -e "\n${YELLOW}Presione ENTER para volver al menú...${NC}"
    read
done

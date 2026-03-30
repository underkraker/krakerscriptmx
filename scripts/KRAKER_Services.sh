#!/bin/bash
# KRAKER MASTER - Service Manager Utility
# Versión 1.0 - Gestión de Puertos y Protocolos

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# Listado de Servicios Clave (Unificado)
# 1: Nombre Servicio/Proceso, 2: Etiqueta, 3: Tipo (systemd|screen|binary)
SERVICES=("xray" "hysteria-server" "kraker_ssl" "kraker-dns" "badvpn-udpgw" "stunnel4" "dropbear")
LABELS=("Xray (Reality/VMess/Trojan)" "Hysteria v2 (UDP 443)" "SSL Gateway (Python 443)" "SlowDNS (UDP 53)" "UDP Gaming (BandVPN)" "VPN SSL (Stunnel)" "SSH Dropbear")
TYPES=("systemd" "systemd" "screen" "systemd" "binary" "systemd" "systemd")

get_status() {
    local type=$1
    local name=$2
    case $type in
        systemd) systemctl is-active --quiet "$name" && echo -e "${GREEN}[ACTIVO]${NC}" || echo -e "${RED}[DETENIDO]${NC}" ;;
        screen) screen -ls | grep -q "$name" && echo -e "${GREEN}[ACTIVO]${NC}" || echo -e "${RED}[DETENIDO]${NC}" ;;
        binary) pgrep -f "$name" > /dev/null && echo -e "${GREEN}[ACTIVO]${NC}" || echo -e "${RED}[DETENIDO]${NC}" ;;
    esac
}

manage_service() {
    local service=$1
    local label=$2
    local type=$3
    clear
    msg_banner
    msg_header "GESTIONANDO: $label"
    echo -e "Estado Actual: $(get_status "$type" "$service")"
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[1]${NC} INICIAR SERVICIO"
    echo -e "  ${YELLOW}[2]${NC} DETENER SERVICIO (LIBERAR PUERTO)"
    echo -e "  ${YELLOW}[3]${NC} REINICIAR SERVICIO"
    echo -e "  ${YELLOW}[0]${NC} VOLVER"
    echo -e "${BARRA}"
    echo -en "Seleccione una acción: "
    read cmd

    case $cmd in
        1) 
           [[ $type == "systemd" ]] && systemctl start "$service"
           [[ $type == "screen" ]] && echo -e "${YELLOW}Inicia el servicio desde su instalador (04).${NC}" && sleep 2
           [[ $type == "binary" ]] && echo -e "${YELLOW}Inicia el servicio desde su instalador (08).${NC}" && sleep 2
           ;;
        2) 
           [[ $type == "systemd" ]] && systemctl stop "$service"
           [[ $type == "screen" ]] && screen -X -S "$service" quit > /dev/null 2>&1
           [[ $type == "binary" ]] && pkill -f "$service"
           fuser -k 443/tcp > /dev/null 2>&1 # Limpieza agresiva de puertos comunes
           ;;
        3) 
           [[ $type == "systemd" ]] && systemctl restart "$service"
           ;;
        0) return ;;
    esac
    echo -e "${GREEN}✔ Acción completada!${NC}"
    sleep 1
}

main_service_menu() {
    clear
    msg_banner
    msg_header "GESTOR DE SERVICIOS KRAKER"
    echo -e "Controla el encendido/apagado de cada puerto:"
    echo -e "${BARRA}"
    
    for i in "${!SERVICES[@]}"; do
        printf "  ${YELLOW}[%02d]${NC} %-30s %b\n" $((i+1)) "${LABELS[$i]}" "$(get_status "${TYPES[$i]}" "${SERVICES[$i]}")"
    done
    
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[00]${NC} VOLVER AL MENU PRINCIPAL"
    echo -e "${BARRA}"
    echo -en "Opción: "
    read opt

    [[ $opt == "0" || $opt == "00" ]] && return 1
    
    index=$((opt - 1))
    if [[ $index -ge 0 && $index -lt ${#SERVICES[@]} ]]; then
        manage_service "${SERVICES[$index]}" "${LABELS[$index]}" "${TYPES[$index]}"
    else
        echo -e "${RED}Opción inválida!${NC}"
        sleep 1
    fi
    return 0
}

# Bucle del Gestor
while main_service_menu; do
    :
done

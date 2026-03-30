#!/bin/bash
# KRAKER MASTER - Service Manager Utility
# Versión 1.0 - Gestión de Puertos y Protocolos

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# Listado de Servicios Clave
SERVICES=("xray" "hysteria-server" "kraker-dns" "stunnel4" "dropbear")
LABELS=("Xray (Reality/VMess/Trojan)" "Hysteria v2 (UDP 443)" "SlowDNS (UDP 53)" "VPN SSL (Stunnel)" "SSH Dropbear")

get_status() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${GREEN}[ACTIVO]${NC}"
    else
        echo -e "${RED}[DETENIDO]${NC}"
    fi
}

manage_service() {
    local service=$1
    local label=$2
    clear
    msg_banner
    msg_header "GESTIONANDO: $label"
    echo -e "Estado Actual: $(get_status "$service")"
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[1]${NC} INICIAR SERVICIO"
    echo -e "  ${YELLOW}[2]${NC} DETENER SERVICIO (LIBERAR PUERTO)"
    echo -e "  ${YELLOW}[3]${NC} REINICIAR SERVICIO"
    echo -e "  ${YELLOW}[0]${NC} VOLVER"
    echo -e "${BARRA}"
    echo -en "Seleccione una acción: "
    read cmd

    case $cmd in
        1) systemctl start "$service" ;;
        2) systemctl stop "$service" ;;
        3) systemctl restart "$service" ;;
        0) return ;;
    esac
    echo -e "${GREEN}✔ Acción completada!${NC}"
    sleep 1
}

main_service_menu() {
    clear
    msg_banner
    msg_header "GESTOR DE SERVICIOS KRAKER"
    echo -e "Selecciona un servicio para administrar sus puertos:"
    echo -e "${BARRA}"
    
    for i in "${!SERVICES[@]}"; do
        printf "  ${YELLOW}[%02d]${NC} %-30s %b\n" $((i+1)) "${LABELS[$i]}" "$(get_status "${SERVICES[$i]}")"
    done
    
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[00]${NC} VOLVER AL MENU PRINCIPAL"
    echo -e "${BARRA}"
    echo -en "Opción: "
    read opt

    [[ $opt == "0" || $opt == "00" ]] && return 1
    
    index=$((opt - 1))
    if [[ $index -ge 0 && $index -lt ${#SERVICES[@]} ]]; then
        manage_service "${SERVICES[$index]}" "${LABELS[$index]}"
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

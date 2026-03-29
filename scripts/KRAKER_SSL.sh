#!/bin/bash
# KRAKER MASTER - SSL GATEWAY MANAGER
# Gestión Avanzada de Protocolos SSL (Dual Mode: WS + Direct)

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

setup_protocol() {
    msg_header "SSL GATEWAY (DUAL)"
    echo -e "${YELLOW}[!] Configurando SSL Gateway (KRAKER VPS)...${NC}"
    read -p "Ingresa el SNI Bug de tu compañía: " BUG
    [[ -z $BUG ]] && BUG="cdn-global.configcat.com"

    # Generar Certificado de Camuflaje
    mkdir -p /etc/ws_ssl
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ws_ssl/server.key -out /etc/ws_ssl/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null
    
    # Liberar puerto 443 e iniciar
    setup_motd
    fuser -k 443/tcp > /dev/null 2>&1
    screen -dmS "kraker_ssl" python3 "$SOURCE_DIR/KRAKER_SSL_Gateway.py" "443" "/etc/ws_ssl/server.crt" "/etc/ws_ssl/server.key"
    
    echo -e "${GREEN}[*] KRAKER VPS - Gateway Dual Iniciado en Puerto 443${NC}"
    echo -e "${YELLOW}[*] Redirección interna: Puerto 80 (SSH/Dropbear)${NC}"
    sleep 3
}

stop_protocol() {
    msg_header "SSL GATEWAY STOP"
    screen -X -S "kraker_ssl" quit > /dev/null 2>&1
    fuser -k 443/tcp > /dev/null 2>&1
    echo -e "${GREEN}[*] Servicio KRAKER SSL detenido.${NC}"
    sleep 2
}

menu() {
    msg_header "SSL GATEWAY MENU"
    echo -e "${GREEN}[1] > ${YELLOW}INICIAR GATEWAY DUAL (WS+Direct)${NC}"
    echo -e "${GREEN}[2] > ${YELLOW}DETENER GATEWAY${NC}"
    echo -e "${GREEN}[3] > ${YELLOW}MONITOR DE LOGS${NC}"
    echo -e "${BARRA}"
    echo -e "${GREEN}[0] > ${RED}SALIR${NC}"
    read -p "Alternativa: " OPC
    case $OPC in
        1) setup_protocol ; menu ;;
        2) stop_protocol ; menu ;;
        3) screen -r kraker_ssl ; menu ;;
        0) exit ;;
        *) menu ;;
    esac
}

# Install Deps
install_deps screen openssl net-tools python3
menu

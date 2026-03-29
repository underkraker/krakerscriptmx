#!/bin/bash
# KRAKER MASTER - SSL GATEWAY MANAGER
# Gestión Avanzada de Protocolos SSL (Dual Mode: WS + Direct)

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

setup_protocol() {
    msg_header "SSL GATEWAY (DUAL)"
    echo -e "${YELLOW}[!] Configurando SSL Gateway (KRAKER MASTER)...${NC}"
    read -p "Ingresa el SNI Bug de tu compañía: " BUG
    [[ -z $BUG ]] && BUG="cdn-global.configcat.com"

    # 1. Liberar puerto 80 y 443
    echo -e "${YELLOW}[*] Liberando puertos y deteniendo conflictos...${NC}"
    systemctl stop apache2 nginx > /dev/null 2>&1
    fuser -k 80/tcp 443/tcp > /dev/null 2>&1
    
    # 2. Detectar puerto de destino (Prioridad 80, secundaria 143)
    local TARGET_PORT=80
    if ! ss -lnpt | grep -q ":80 "; then
        if ss -lnpt | grep -q ":143 "; then
            TARGET_PORT=143
            echo -e "${YELLOW}[!] Port 80 down. Redirigiendo a Dropbear (143).${NC}"
        else
            echo -e "${RED}[!] Error: No se detectó Dropbear/SSH en puerto 80 ni 143.${NC}"
            sleep 3 && return
        fi
    fi

    # 3. Generar Certificado
    mkdir -p /etc/ws_ssl
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ws_ssl/server.key -out /etc/ws_ssl/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null
    
    # 4. Iniciar Python Gateway en segundo plano
    screen -dmS "kraker_ssl" python3 "$SOURCE_DIR/KRAKER_SSL_Gateway.py" "443" "/etc/ws_ssl/server.crt" "/etc/ws_ssl/server.key" "127.0.0.1" "$TARGET_PORT"
    
    echo -e "${GREEN}[*] KRAKER MASTER - Gateway Dual Iniciado en Puerto 443${NC}"
    echo -e "${YELLOW}[*] Redirección interna: Puerto $TARGET_PORT${NC}"
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

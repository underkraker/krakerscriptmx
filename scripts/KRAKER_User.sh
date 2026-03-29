#!/bin/bash
# KRAKER MASTER - GESTIÓN DE USUARIOS
# Versión 2.0 Professional Edition

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

XRAY_CONF="/usr/local/etc/xray/config.json"
USER_DB="/etc/kraker_users.db"
[[ ! -f $USER_DB ]] && touch $USER_DB

# --- FUNCIONES ---

generate_ticket() {
    local user=$1
    local pass=$2
    local exp=$3
    local limit=$4
    local uuid=$5
    local ip=$(get_ip)
    local ports=$(get_active_ports)
    
    msg_header "TICKET DE ACCESO ELITE"
    echo -e "${CYAN}  ╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║${GREEN}            🐲 DETALLES DE CONEXIÓN KRAKER MASTER 🐲            ${CYAN}║${NC}"
    echo -e "${CYAN}  ╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║ ${WHITE}DIRECCIÓN IP  :${NC} ${GREEN}$ip${NC}"
    echo -e "${CYAN}  ║ ${WHITE}USUARIO       :${NC} ${YELLOW}$user${NC}"
    echo -e "${CYAN}  ║ ${WHITE}CONTRASEÑA    :${NC} ${YELLOW}$pass${NC}"
    echo -e "${CYAN}  ║ ${WHITE}LÍMITE CONEX. :${NC} ${YELLOW}$limit${NC}"
    echo -e "${CYAN}  ║ ${WHITE}EXPIRACIÓN    :${NC} ${RED}$exp${NC}"
    echo -e "${CYAN}  ╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║ ${WHITE}PUERTOS ACTIVOS:${NC} ${CYAN}$ports${NC}"
    [[ ! -z $uuid && $uuid != "N/A" ]] && echo -e "${CYAN}  ║ ${WHITE}UUID XRAY     :${NC} ${MAGENTA}$uuid${NC}"
    echo -e "${CYAN}  ╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}  ║ ${GREEN}INSTRUCCIONES DE CONEXIÓN:                                       ${CYAN}║${NC}"
    echo -e "${CYAN}  ║ ${WHITE}1. SSH/DROPBEAR: Usa puertos 80, 143 o 442 (HTTP Custom/Injector)${CYAN}║${NC}"
    echo -e "${CYAN}  ║ ${WHITE}2. VLESS/VMESS : Usa puerto 443 o 2083 (NapsternetV/v2rayNG)     ${CYAN}║${NC}"
    echo -e "${CYAN}  ║ ${WHITE}3. UDP GAMING: Puertos 7100-7300 (Activar en configuración)     ${CYAN}║${NC}"
    echo -e "${CYAN}  ╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BARRA}"
}

add_user() {
    msg_header "AÑADIR NUEVO USUARIO"
    read -p "Nombre de Usuario: " USERNAME
    [[ -z $USERNAME ]] && return
    
    if grep -q "^$USERNAME:" /etc/passwd; then
        echo -e "${RED}[!] El usuario ya existe en el sistema.${NC}"
        sleep 2 && return
    fi

    read -p "Contraseña: " PASSWORD
    [[ -z $PASSWORD ]] && PASSWORD=$(openssl rand -hex 4)
    
    read -p "Límite de Conexiones [2]: " LIMIT
    [[ -z $LIMIT ]] && LIMIT=2

    read -p "Días de duración [30]: " DAYS
    [[ -z $DAYS ]] && DAYS=30
    EXP_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
    
    echo -e "${YELLOW}[*] Creando cuenta en el sistema...${NC}"
    useradd -M -s /bin/false -e $EXP_DATE $USERNAME
    echo "$USERNAME:$PASSWORD" | chpasswd
    
    # Aplicar Límite SSH
    echo "$USERNAME hard maxlogins $LIMIT" >> /etc/security/limits.conf
    
    # Integración con Xray (si existe)
    local UUID="N/A"
    if [[ -f $XRAY_CONF ]]; then
        echo -e "${YELLOW}[*] Generando UUID para Xray/VLESS/VMess...${NC}"
        UUID=$(xray uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid)
        echo -e "${YELLOW}[*] Actualizando configuración de Xray...${NC}"
        
        jq --arg id "$UUID" --arg email "$USERNAME" \
           '(.inbounds[] | select(.protocol == "vless" or .protocol == "vmess") | .settings.clients) += [{"id": $id, "email": $email, "flow": "xtls-rprx-vision"}]' \
           $XRAY_CONF > ${XRAY_CONF}.tmp && mv ${XRAY_CONF}.tmp $XRAY_CONF
           
        systemctl restart xray > /dev/null 2>&1
    fi

    # Guardar en DB local
    echo "$USERNAME|$PASSWORD|$EXP_DATE|$UUID|$LIMIT" >> $USER_DB
    
    generate_ticket "$USERNAME" "$PASSWORD" "$EXP_DATE" "$LIMIT" "$UUID"
    echo -e "${CYAN}Presione ENTER para continuar...${NC}"
    read
}

delete_user() {
    msg_header "ELIMINAR USUARIO"
    read -p "Nombre de Usuario a eliminar: " USERNAME
    [[ -z $USERNAME ]] && return

    if ! grep -q "^$USERNAME:" /etc/passwd; then
        echo -e "${RED}[!] El usuario no existe.${NC}"
        sleep 2 && return
    fi

    echo -e "${YELLOW}[*] Eliminando del sistema...${NC}"
    userdel -f $USERNAME
    sed -i "/$USERNAME hard maxlogins/d" /etc/security/limits.conf
    
    # Limpiar Xray
    if [[ -f $XRAY_CONF ]]; then
        echo -e "${YELLOW}[*] Limpiando configuración de Xray...${NC}"
        jq --arg email "$USERNAME" \
           '(.inbounds[].settings.clients) |= map(select(.email != $email))' \
           $XRAY_CONF > ${XRAY_CONF}.tmp && mv ${XRAY_CONF}.tmp $XRAY_CONF
        systemctl restart xray > /dev/null 2>&1
    fi

    # Limpiar DB local
    sed -i "/^$USERNAME|/d" $USER_DB
    
    echo -e "${GREEN}✔ Usuario '$USERNAME' eliminado.${NC}"
    sleep 2
}

list_users() {
    msg_header "LISTADO DE USUARIOS KRAKER"
    echo -e "${YELLOW}%-12s %-12s %-10s %-8s %-15s${NC}" "USUARIO" "PASSWORD" "EXPIRA" "LIMITE" "ESTADO"
    echo -e "${BARRA}"
    
    while IFS='|' read -r user pass exp uuid limit; do
        [[ -z $limit ]] && limit="2"
        current_date=$(date +%s)
        exp_date=$(date -d "$exp" +%s)
        if [[ $current_date -gt $exp_date ]]; then
            status="${RED}EXPIRADO${NC}"
        else
            status="${GREEN}ACTIVO${NC}"
        fi
        printf "%-12s %-12s %-10s %-8s %b\n" "$user" "$pass" "$exp" "$limit" "$status"
    done < $USER_DB
    
    echo -e "${BARRA}"
    echo -e "${CYAN}Presione ENTER para volver...${NC}"
    read
}

# --- MENU USUARIOS ---

while true; do
    msg_header "GESTIÓN DE USUARIOS ELITE"
    echo -e "  ${YELLOW}[1]${NC} ${WHITE}AÑADIR USUARIO${NC}"
    echo -e "  ${YELLOW}[2]${NC} ${WHITE}ELIMINAR USUARIO${NC}"
    echo -e "  ${YELLOW}[3]${NC} ${WHITE}LISTAR USUARIOS${NC}"
    echo -e "  ${BARRA}"
    echo -e "  ${YELLOW}[0]${NC} ${RED}VOLVER AL MENÚ PRINCIPAL${NC}"
    echo -e "${BARRA}"
    echo -en "  ${CYAN}SELECCIONE UNA OPCIÓN: ${NC}"
    read opt

    case $opt in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        0) exit 0 ;;
        *) echo -e "${RED}Opción inválida!${NC}" && sleep 1 ;;
    esac
done

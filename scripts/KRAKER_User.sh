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
    
    read -p "Días de duración [30]: " DAYS
    [[ -z $DAYS ]] && DAYS=30
    EXP_DATE=$(date -d "+$DAYS days" +%Y-%m-%d)
    
    echo -e "${YELLOW}[*] Creando cuenta en el sistema...${NC}"
    useradd -M -s /bin/false -e $EXP_DATE $USERNAME
    echo "$USERNAME:$PASSWORD" | chpasswd
    
    # Integración con Xray (si existe)
    if [[ -f $XRAY_CONF ]]; then
        echo -e "${YELLOW}[*] Generando UUID para Xray/VLESS/VMess...${NC}"
        UUID=$(xray uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid)
        echo -e "${YELLOW}[*] Actualizando configuración de Xray...${NC}"
        
        # Insertar en el primer inbound que no sea trojan (asumiendo VLESS/VMess)
        jq --arg id "$UUID" --arg email "$USERNAME" \
           '(.inbounds[] | select(.protocol == "vless" or .protocol == "vmess") | .settings.clients) += [{"id": $id, "email": $email, "flow": "xtls-rprx-vision"}]' \
           $XRAY_CONF > ${XRAY_CONF}.tmp && mv ${XRAY_CONF}.tmp $XRAY_CONF
           
        systemctl restart xray > /dev/null 2>&1
    fi

    # Guardar en DB local
    echo "$USERNAME|$PASSWORD|$EXP_DATE|${UUID:-N/A}" >> $USER_DB
    
    msg_header "USUARIO CREADO"
    echo -e "${GREEN}✔ Usuario '$USERNAME' creado con éxito!${NC}"
    echo -e "${BARRA}"
    echo -e "${CYAN}Password  :${NC} $PASSWORD"
    echo -e "${CYAN}Expira    :${NC} $EXP_DATE"
    [[ ! -z $UUID ]] && echo -e "${CYAN}Xray UUID :${NC} $UUID"
    echo -e "${BARRA}"
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
    echo -e "${YELLOW}%-15s %-15s %-12s %-20s${NC}" "USUARIO" "PASSWORD" "EXPIRA" "ESTADO"
    echo -e "${BARRA}"
    
    while IFS='|' read -r user pass exp uuid; do
        current_date=$(date +%s)
        exp_date=$(date -d "$exp" +%s)
        if [[ $current_date -gt $exp_date ]]; then
            status="${RED}EXPIRADO${NC}"
        else
            status="${GREEN}ACTIVO${NC}"
        fi
        printf "%-15s %-15s %-12s %b\n" "$user" "$pass" "$exp" "$status"
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

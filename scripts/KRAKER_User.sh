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
    
    # 1. Identidad de Red (Dominio vs IP)
    local identity=$(get_ip)
    [[ -f "/etc/kraker_domain" ]] && identity=$(cat /etc/kraker_domain)
    
    # 2. Análisis Dinámico de Puertos
    local ports=$(get_active_ports)
    
    msg_header "COMPROBANTE DE ACCESO ELITE"
    echo -e "  ${GREEN}✅ CUENTA SSH CREADA${NC}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}👤 Usuario:${NC} ${YELLOW}$user${NC}"
    echo -e "  ${WHITE}🔑 Pass   :${NC} ${YELLOW}$pass${NC}"
    echo -e "  ${WHITE}📅 Exp    :${NC} ${RED}$exp${NC}"
    echo -e "  ${WHITE}🔐 IPs    :${NC} ${YELLOW}$limit${NC} | ${WHITE}📦 Datos:${NC} ${GREEN}Ilimitado${NC}"
    echo -e "  ${WHITE}🎨 Banner :${NC} ${GREEN}Default${NC}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}🔌 PUERTOS PRINCIPALES${NC}"
    
    # Mostrar solo si están activos
    [[ $ports == *"80"* ]] && echo -e "  ${WHITE}• SSH WS:${NC} ${CYAN}80 8080${NC}"
    [[ $ports == *"443"* ]] && echo -e "  ${WHITE}• SSL WS:${NC} ${CYAN}443${NC}"
    [[ $ports == *"443"* ]] && echo -e "  ${WHITE}• SSL TUNNEL:${NC} ${CYAN}443${NC}"
    [[ $ports == *"7100"* ]] && echo -e "  ${WHITE}• BADVPN:${NC} ${CYAN}7100 7300${NC}"
    [[ $ports == *"143"* || $ports == *"442"* ]] && echo -e "  ${WHITE}• DROPBEAR:${NC} ${CYAN}143 442${NC}"
    
    # Detección de Hysteria v2
    if systemctl is-active --quiet hysteria-server; then
        local hy_port=$(grep 'listen:' /etc/hysteria/config.yaml | cut -d':' -f3)
        local hy_pass=$(grep 'password:' /etc/hysteria/config.yaml | xargs | cut -d' ' -f2)
        local hy_sni=$(grep 'url:' /etc/hysteria/config.yaml | cut -d'/' -f3)
        [[ -z $hy_port ]] && hy_port="443"
        echo -e "  ${WHITE}• UDP HYSTERIA:${NC} ${CYAN}$hy_port${NC}"
    fi
    
    # Detección de SlowDNS
    if systemctl is-active --quiet kraker-dns; then
        echo -e "  ${WHITE}• SLOWDNS:${NC} ${CYAN}53 5300${NC}"
    fi
    
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}🌐 Dominio:${NC} ${GREEN}$identity${NC}"
    echo -e "  ${YELLOW}📱 HTTP Custom:${NC}"
    echo -e "  ${WHITE}$identity:443@$user:$pass${NC}"
    echo -e "  ${WHITE}$identity:80@$user:$pass${NC}"
    
    # Bloque Hysteria (Si existe)
    if [[ ! -z $hy_port ]]; then
        echo -e ""
        echo -e "  ${MAGENTA}🔮 UDP HTTP Hysteria:${NC}"
        echo -e "  ${WHITE}$identity | UDP Port: $hy_port${NC}"
        echo -e "  ${WHITE}🔗 Link Hysteria:${NC}"
        echo -e "  ${CYAN}hysteria2://$hy_pass@$(get_ip):$hy_port/?insecure=1&sni=$hy_sni#KRAKER-Hysteria2${NC}"
    fi

    # Bloque SlowDNS (Si existe)
    if systemctl is-active --quiet kraker-dns; then
        echo -e ""
        echo -e "  ${YELLOW}🐢 SLOWDNS:${NC}"
        local pub_key=$(cat /etc/kraker_dns/server.pub 2>/dev/null)
        echo -e "  ${WHITE}• Key:${NC} ${CYAN}$pub_key${NC}"
        echo -e "  ${WHITE}• NS :${NC} ${CYAN}script.$identity${NC}"
    fi
    
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    
    # Asegurar que /bin/false sea un shell válido
    grep -q "^/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
    
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

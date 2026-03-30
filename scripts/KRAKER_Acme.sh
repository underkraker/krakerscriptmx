#!/bin/bash
# KRAKER MASTER - GESTOR DE DOMINIOS (ACME)
# Versión 4.5 Supreme Edition

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

install_acme() {
    msg_header "INSTALANDO MOTOR ACME.SH"
    if [[ -d "$HOME/.acme.sh" ]]; then
        echo -e "${GREEN}[✔] Acme.sh ya está instalado.${NC}"
    else
        echo -e "${YELLOW}[*] Instalando dependencias y acme.sh...${NC}"
        install_deps socat curl cron
        curl https://get.acme.sh | sh -s email=admin@$(hostname) > /dev/null 2>&1
        source "$HOME/.bashrc"
        echo -e "${GREEN}[✔] Acme.sh instalado correctamente.${NC}"
    fi
    sleep 2
}

issue_cert() {
    msg_header "EXPEDICIÓN DE CERTIFICADO REAL"
    echo -e "${YELLOW}[!] REQUISITO: Tu dominio/subdominio debe apuntar a esta IP [$(get_ip)]${NC}"
    echo -e "${BARRA}"
    read -p "Ingresa tu Dominio/Subdominio: " DOMAIN
    [[ -z $DOMAIN ]] && echo -e "${RED}[!] Dominio requerido.${NC}" && sleep 2 && return

    # Detener servicios que ocupan el puerto 80 temporalmente
    echo -e "${YELLOW}[*] Liberando puerto 80...${NC}"
    fuser -k 80/tcp > /dev/null 2>&1
    systemctl stop apache2 nginx > /dev/null 2>&1

    echo -e "${YELLOW}[*] Solicitando certificado para $DOMAIN...${NC}"
    "$HOME/.acme.sh"/acme.sh --set-default-ca --server letsencrypt > /dev/null 2>&1
    "$HOME/.acme.sh"/acme.sh --issue -d "$DOMAIN" --standalone --force

    if [[ -d "$HOME/.acme.sh/${DOMAIN}_ecc" ]]; then
        echo -e "${GREEN}[✔] Certificado emitido con éxito.${NC}"
        
        # Persistencia de Dominio para Tickets
        echo "$DOMAIN" > /etc/kraker_domain
        
        # Copiar y vincular a la ruta global del panel para compatibilidad total
        mkdir -p /etc/ws_ssl
        cp "$HOME/.acme.sh/${DOMAIN}_ecc/$DOMAIN.cer" "/etc/ws_ssl/server.crt"
        cp "$HOME/.acme.sh/${DOMAIN}_ecc/$DOMAIN.key" "/etc/ws_ssl/server.key"
        
        echo -e "${GREEN}[*] Certificado vinculado a /etc/ws_ssl/ con éxito.${NC}"
        echo -e "${YELLOW}[!] Reinicia tus servicios SSL para aplicar el cambio.${NC}"
    else
        echo -e "${RED}[!] Error en la emisión. Verifica que tu dominio apunte a $(get_ip)${NC}"
    fi
    
    # Reiniciar servicios (Solo Dropbear por ahora, el usuario hará el resto)
    systemctl start dropbear > /dev/null 2>&1
    sleep 3
}

# --- MENU DE ACME ---
menu() {
    msg_header "GESTOR DE CERTIFICADOS REALES"
    echo -e "  ${YELLOW}[1]${NC} ${WHITE}INSTALAR MOTOR ACME.SH${NC}"
    echo -e "  ${YELLOW}[2]${NC} ${WHITE}GENERAR CERTIFICADO DE DOMINIO REAL (Let's Encrypt)${NC}"
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[0]${NC} ${RED}VOLVER AL MENU SISTEMA${NC}"
    echo -e "${BARRA}"
    read -p "Opción: " opt
    case $opt in
        1) install_acme ; menu ;;
        2) issue_cert ; menu ;;
        0) exit 0 ;;
        *) menu ;;
    esac
}

menu

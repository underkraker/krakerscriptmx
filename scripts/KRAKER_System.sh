#!/bin/bash
# KRAKER MASTER - SISTEMA Y MANTENIMIENTO
# Versión 4.0 Elite Edition

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

enable_bbr() {
    msg_header "OPTIMIZACIÓN TCP BBR (GOOGLE)"
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo -e "${GREEN}[✔] TCP BBR ya está activado y funcionando.${NC}"
    else
        echo -e "${YELLOW}[*] Activando TCP BBR para mayor velocidad...${NC}"
        modprobe tcp_bbr > /dev/null 2>&1
        echo "tcp_bbr" > /etc/modules-load.d/bbr.conf 2>/dev/null
        sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
        sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        echo -e "${GREEN}[✔] TCP BBR activado con éxito.${NC}"
    fi
    sleep 2
}

auto_clean_users() {
    msg_header "LIMPIADOR DE USUARIOS EXPIRADOS"
    local USER_DB="/etc/kraker_users.db"
    local XRAY_CONF="/usr/local/etc/xray/config.json"
    local count=0

    [[ ! -f $USER_DB ]] && echo -e "${RED}[!] Base de datos no encontrada.${NC}" && sleep 2 && return

    echo -e "${YELLOW}[*] Escaneando usuarios caducados...${NC}"
    local current_ts=$(date +%s)
    local temp_db="/tmp/kraker_users.tmp"
    touch $temp_db

    while IFS='|' read -r user pass exp uuid limit; do
        exp_ts=$(date -d "$exp" +%s 2>/dev/null)
        if [[ $current_ts -gt $exp_ts ]]; then
            echo -e "${RED}[-] Usuario expirado: $user ($exp). Eliminando y bloqueando...${NC}"
            pkill -u "$user" 2>/dev/null
            userdel -f $user > /dev/null 2>&1
            sed -i "/$user hard maxlogins/d" /etc/security/limits.conf > /dev/null 2>&1
            ((count++))
        else
            echo "$user|$pass|$exp|$uuid|$limit" >> $temp_db
        fi
    done < $USER_DB

    mv $temp_db $USER_DB
    
    echo -e "${GREEN}[✔] Limpieza sistemática completada. Cuentas eliminadas: $count${NC}"
    sleep 2
}

manage_cron() {
    msg_header "TAREA DE LIMPIEZA DIARIA"
    if crontab -l 2>/dev/null | grep -q "KRAKER_System.sh auto_clean"; then
        echo -e "${GREEN}[✔] La limpieza automática ya está programada (Medianoche).${NC}"
    else
        (crontab -l 2>/dev/null; echo "0 0 * * * $SOURCE_DIR/KRAKER_System.sh auto_clean > /dev/null 2>&1") | crontab -
        echo -e "${GREEN}[✔] Tarea programada: Limpieza automática diaria a medianoche.${NC}"
    fi
    sleep 2
}

backup_system() {
    msg_header "COPIA DE SEGURIDAD TOTAL (PRE-TURBO)"
    local date=$(date +%Y-%m-%d_%H-%M)
    local file="/root/KRAKER_FULL_BACKUP_$date.tar.gz"
    
    echo -e "${YELLOW}[*] Comprimiendo Base de Datos, Scripts y Servicios...${NC}"
    # Incluir DB, Configs, Scripts del panel y las unidades de Systemd
    tar -czf "$file" \
        /etc/kraker_users.db \
        /etc/kraker_domain \
        /usr/local/etc/xray/config.json \
        /etc/ws_ssl/server.crt \
        /etc/ws_ssl/server.key \
        $SOURCE_DIR \
        /etc/systemd/system/kraker-* \
        /etc/systemd/system/hysteria-server.service > /dev/null 2>&1
        
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}[✔] Backup Creado: $file${NC}"
        echo -e "${YELLOW}[!] Este archivo contiene TODA tu configuración actual.${NC}"
    else
        echo -e "${RED}[!] Error al crear el backup. Revisa el espacio en disco.${NC}"
    fi
    sleep 3
}

install_watchdog() {
    msg_header "ACTIVAR GUARDIÁN DE SERVICIOS"
    chmod +x "$SOURCE_DIR/KRAKER_Watchdog.sh"
    if crontab -l 2>/dev/null | grep -q "KRAKER_Watchdog.sh"; then
        echo -e "${GREEN}[✔] El Guardián ya está activo (Revisión cada 1 min).${NC}"
    else
        (crontab -l 2>/dev/null; echo "* * * * * $SOURCE_DIR/KRAKER_Watchdog.sh > /dev/null 2>&1") | crontab -
        echo -e "${GREEN}[✔] Guardián activado: Tus servicios están protegidos 24/7.${NC}"
    fi
    sleep 2
}

# --- MENU DE SISTEMA ---
menu() {
    msg_header "SISTEMA Y OPTIMIZACIÓN"
    echo -e "  ${YELLOW}[1]${NC} ${WHITE}ACTIVAR TCP BBR (OPTIMIZACIÓN RED)${NC}"
    echo -e "  ${YELLOW}[2]${NC} ${WHITE}EJECUTAR LIMPIADOR DE EXPIRADOS${NC}"
    echo -e "  ${YELLOW}[3]${NC} ${WHITE}ACTIVAR LIMPIEZA DIARIA (AUTO-CRON)${NC}"
    echo -e "  ${YELLOW}[4]${NC} ${WHITE}CREAR COPIA DE SEGURIDAD (BACKUP)${NC}"
    echo -e "  ${YELLOW}[5]${NC} ${WHITE}CONFIGURAR DOMINIO REAL (SSL ACME)${NC}"
    echo -e "  ${YELLOW}[6]${NC} ${WHITE}ACTIVAR GUARDIÁN (WATCHDOG)${NC}"
    echo -e "${BARRA}"
    echo -e "  ${YELLOW}[0]${NC} ${RED}VOLVER AL MENU PRINCIPAL${NC}"
    echo -e "${BARRA}"
    read -p "Opción: " opt
    case $opt in
        1) enable_bbr ; menu ;;
        2) auto_clean_users ; menu ;;
        3) manage_cron ; menu ;;
        4) backup_system ; menu ;;
        5) bash "$SOURCE_DIR/KRAKER_Acme.sh" ; menu ;;
        6) install_watchdog ; menu ;;
        0) exit 0 ;;
        *) menu ;;
    esac
}

# Soporte para ejecución vía cron o línea de comandos
if [[ "$1" == "auto_clean" ]]; then
    auto_clean_users
elif [[ "$1" == "enable_bbr" ]]; then
    enable_bbr
else
    menu
fi

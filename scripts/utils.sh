#!/bin/bash
# KRAKER MASTER - Shared Utilities & UI Library
# Optimized for VPS Management - Elite Dashboard

# Colores Elite Master - Paleta Extendida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Simbología de Élite
ON="${GREEN}●${NC}"
OFF="${RED}○${NC}"
ICON_V2="${CYAN}🐉${NC}"
ICON_XRAY="${MAGENTA}🛡️${NC}"
ICON_GAME="${YELLOW}🎮${NC}"
ICON_SSL="${BLUE}🔒${NC}"
ICON_SYS="${GRAY}⚙️${NC}"

# Líneas y Bordes Unicode
BARRA="${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
B_TOP="${GRAY}╔════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
B_BOT="${GRAY}╚════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
B_SEP="${GRAY}╟────────────────────────────────────────────────────────────────────────────────────────────────────╢${NC}"

# ASCII Art Visual Branding Master (Minimalista Galáctico Centrado Wide)
msg_banner() {
    clear
    echo -e "           ${CYAN}🐲 Ｋ Ｒ Ａ Ｋ Ｅ Ｒ   ${GREEN}Ｍ Ａ Ｓ Ｔ Ｅ Ｒ   ${WHITE}Ｐ Ａ Ｎ Ｅ Ｌ 🐲${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "                      ${GRAY}[ ELITE EDITION - VERSION EXTREME ]${NC}"
}

# Live Status Indicator
get_status() {
    local port=$1
    if ss -ntlp | grep -q ":$port " || ss -nulp | grep -q ":$port "; then
        echo -e "${ON}"
    else
        echo -e "${OFF}"
    fi
}

# Simple Header for sub-scripts
msg_header() {
    clear
    echo -e "${B_TOP}"
    echo -e "  ${ICON_XRAY} ${CYAN}KRAKER MASTER PANEL - $1${NC}"
    echo -e "${B_BOT}"
}

# System Checks
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] ¡ERROR! Ejecuta como ROOT.${NC}"
        exit 1
    fi
}

get_ip() {
    IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
    echo "$IP"
}

get_resource_bar() {
    local percent=$1
    local color=$GREEN
    [[ $percent -gt 50 ]] && color=$YELLOW
    [[ $percent -gt 80 ]] && color=$RED
    
    local width=20
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    echo -ne "${color}${bar}${GRAY}${GRAY:0:0} ${percent}%${NC}"
}

# Dependency Manager
install_deps() {
    local deps=("$@")
    echo -e "${GRAY}[*] Verificando dependencias: ${deps[*]}${NC}"
    apt update -y > /dev/null 2>&1
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${YELLOW}[+] Instalando $dep...${NC}"
            apt install -y "$dep" > /dev/null 2>&1
        fi
    done
}

setup_motd() {
    cat << 'EOF' > /etc/motd
  ██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗██████╗     ██╗   ██╗██████╗ ███████╗
  ██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗    ██║   ██║██╔══██╗██╔════╝
  █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██████╔╝    ██║   ██║██████╔╝███████╗
  ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝ ╚════██║
  ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║  ██║     ╚████╔╝ ██║     ████████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚═╝     ╚══════╝
                                BIENVENIDO A KRAKER VPS
EOF
    sed -i 's/#PrintMotd yes/PrintMotd yes/g' /etc/ssh/sshd_config
    systemctl restart sshd > /dev/null 2>&1
}

# Módulo de Limpieza Master ♻️🚀
clean_vps_ram() {
    # Liberar Caches del Kernel Linux
    sync
    echo 3 > /proc/sys/vm/drop_caches
    # Limpiar Archivos Temporales Antiguos
    rm -rf /tmp/*.log /tmp/*.tmp 2>/dev/null
}

purge_ghost_sessions() {
    # 🏁 PURGADO DE SESIONES FANTASMA (LIBERAR CPU)
    # Matar procesos de protocolos que no tienen usuarios reales (sockets muertos)
    systemctl restart dropbear > /dev/null 2>&1
    systemctl restart stunnel4 > /dev/null 2>&1
    # Liberar RAM en cascada
    clean_vps_ram
}

setup_auto_clean() {
    # Programar Limpieza RAM cada 2 Horas
    if ! crontab -l | grep -q "clean_vps_ram"; then
        (crontab -l 2>/dev/null; echo "0 */2 * * * /usr/bin/kraker --ram-clean > /dev/null 2>&1") | crontab -
    fi
    # Programar Purgado Sesiones Fantasma (CPU) cada 30 Minutos para bajar del 500%
    if ! crontab -l | grep -q "purge_ghost_sessions"; then
        (crontab -l 2>/dev/null; echo "*/30 * * * * /usr/bin/kraker --cpu-clean > /dev/null 2>&1") | crontab -
    fi
}

get_active_users() {
    # Contar usuarios reales por SSH y SSL
    local ssh_users=$(who | wc -l)
    # Contar sesiones SSL Establecidas (PDirect / Python)
    local ssl_users=$(ss -ant | grep -E ":(443|80|442|8080) " | grep "ESTAB" | wc -l)
    echo -e "${GREEN}$((ssh_users + ssl_users))${NC}"
}

get_active_ports() {
    local tcp_show=""
    local udp_show=""
    
    for p in 80 443 143 442 2053 2083 2087 2096 4433; do
        ss -ntlp | grep -q ":$p " && tcp_show+="$p "
    done
    for p in 443 53 5300 36712 7100 7200 7300; do
        ss -nulp | grep -q ":$p " && udp_show+="$p "
    done
    local output=""
    [[ ! -z $tcp_show ]] && output+="${GREEN}TCP:${NC} $tcp_show "
    [[ ! -z $udp_show ]] && output+="${MAGENTA}UDP:${NC} $udp_show "
    echo -e "${output:-NINGUNO}"
}

# Módulo de Banner Híbrido 🛡️🐲🚀
setup_kraker_banner() {
    local CUSTOM_MSG=$(cat /etc/kraker/.client_banner 2>/dev/null || echo "             𝙉𝙀𝙏𝙁𝙍𝙀𝙀 𝙇𝙏𝙈 𝙑𝙋𝙎 𝙈𝙄𝘼𝙈𝙄")
    
    # 🕵️ PIEZA FIJA: MASTER KRAKER (ASCII) 🛡️
    cat << EOF > /etc/kraker_banner
[$(date +%H:%M:%S)] Server Message:
─────────────────────────────────────────────────────────────
           🐲 Ｋ Ｒ Ａ Ｋ Ｅ Ｒ   Ｍ Ａ Ｓ Ｔ Ｅ Ｒ 🐲
─────────────────────────────────────────────────────────────
$CUSTOM_MSG
─────────────────────────────────────────────────────────────
EOF
    
    # 1. Configurar SSH para usar este Banner
    sed -i 's|^#Banner none|Banner /etc/kraker_banner|g' /etc/ssh/sshd_config
    sed -i 's|^Banner.*|Banner /etc/kraker_banner|g' /etc/ssh/sshd_config
    systemctl restart ssh > /dev/null 2>&1
    
    # 2. Configurar Dropbear (Si existe)
    if [[ -f /etc/default/dropbear ]]; then
        sed -i 's|^DROPBEAR_BANNER=.*|DROPBEAR_BANNER="/etc/kraker_banner"|g' /etc/default/dropbear
        # Si no existe la línea, la añadimos
        if ! grep -q "DROPBEAR_BANNER" /etc/default/dropbear; then
            echo 'DROPBEAR_BANNER="/etc/kraker_banner"' >> /etc/default/dropbear
        fi
        systemctl restart dropbear > /dev/null 2>&1
    fi
}

# Módulo de Xray Modular 🛡️🐲🚀
install_xray_modular() {
    # 🕵️ Asegurar que el núcleo oficial esté instalado
    if [[ ! -s /usr/local/bin/xray ]]; then
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    # Crear Estructura de Carpetas Élite
    mkdir -p /usr/local/etc/xray/conf.d/
    
    # 🏁 Crear el Servicio Maestro de Xray (Carga todo el directorio)
    cat << EOF > /etc/systemd/system/xray.service
[Unit]
Description=KRAKER MASTER - Xray Modular Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/conf.d/
Restart=always
RestartSec=3s
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # Crear el outbound por defecto (Freedom) para que los inbounds funcionen
    cat << EOF > /usr/local/etc/xray/conf.d/00_outbounds.json
{
    "log": {"loglevel": "warning"},
    "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
EOF

    systemctl daemon-reload
    systemctl enable xray > /dev/null 2>&1
}

update_client_message() {
    msg_header "PERSONALIZAR BANNER DE CLIENTE"
    echo -e "  ${YELLOW}Sugerencia: Usa negritas o emojis para que resalte.${NC}"
    echo -e "${BARRA}"
    echo -e -n "  ${CYAN}INGRESE SU NUEVO MENSAJE: ${NC}"
    read nuevo_msg
    if [[ ! -z "$nuevo_msg" ]]; then
        mkdir -p /etc/kraker
        echo "          $nuevo_msg" > /etc/kraker/.client_banner
        setup_kraker_banner
        echo -e "\n  ${GREEN}✔ Banner actualizado correctamente.${NC}"
    else
        echo -e "\n  ${RED}❌ Operación cancelada.${NC}"
    fi
    sleep 2
}


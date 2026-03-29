#!/bin/bash
# KRAKER MASTER - Shared Utilities & UI Library
# Optimized for VPS Management - Elite Dashboard

# Colores Premium - Standard Palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Aliases for consistency with legacy scripts
VERDE=$GREEN
ROJO=$RED
AMARILLO=$YELLOW
AZUL=$CYAN
RESET=$NC
BARRA="${CYAN}----------------------------------------------------------------------------------------------------${NC}"

# ASCII Art Visual Branding
msg_banner() {
    clear
    echo -e "${CYAN}  ██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗██████╗     ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ${NC}"
    echo -e "${CYAN}  ██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗${NC}"
    echo -e "${GREEN}  █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██████╔╝    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝${NC}"
    echo -e "${GREEN}  ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗${NC}"
    echo -e "${WHITE}  ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║${NC}"
    echo -e "${WHITE}  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝${NC}"
    echo -e "${YELLOW}                            PANEL DE CONTROL ELITE - VERSION 2.0${NC}"
    echo -e "${BARRA}"
}

# Simple Header for sub-scripts
msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${CYAN}  🐲 KRAKER VPS - $1 🐲${NC}"
    echo -e "${BARRA}"
}

# System Checks
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] ¡ERROR! Este script debe ejecutarse como ROOT.${NC}"
        exit 1
    fi
}

get_ip() {
    IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')
    echo "$IP"
}

# Dependency Manager
install_deps() {
    local deps=("$@")
    echo -e "${YELLOW}[*] Verificando dependencias: ${deps[*]}${NC}"
    apt update -y > /dev/null 2>&1
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${AMARILLO}[+] Instalando $dep...${NC}"
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

get_active_ports() {
    local ports=""
    # Check TCP ports
    for p in 80 443 143 442 2083 2087 2053; do
        ss -ntlp | grep -q ":$p " && ports+="$p "
    done
    # Check UDP ports (BadVPN/Gaming)
    for p in 7100 7200 7300; do
        ss -nulp | grep -q ":$p " && ports+="$p "
    done
    echo "$ports"
}

get_sni_choice() {
    local default_snib="www.google.com"
    echo -e "${YELLOW}[!] Selecciona el tipo de SNI Bug:${NC}"
    echo -e "  ${GREEN}[1]${NC} ${WHITE}Universal SNI ($default_snib - Alta Compatibilidad)${NC}"
    echo -e "  ${GREEN}[2]${NC} ${WHITE}Custom SNI (Ingresar manualmente)${NC}"
    echo -e "${BARRA}"
    read -p "Opción [1]: " SNI_OPT
    
    local rbug=""
    if [[ $SNI_OPT == "2" ]]; then
        read -p "Ingresa el SNI Bug: " rbug
        [[ -z $rbug ]] && rbug="$default_snib"
    else
        rbug="$default_snib"
        echo -e "${GREEN}[*] Usando Universal SNI: $rbug${NC}"
    fi
    echo "$rbug"
}

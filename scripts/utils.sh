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
    
    echo -ne "${color}[${bar}] ${percent}%${NC}"
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
    local gaming=""
    
    # Check Standard TCP ports
    for p in 80 443 143 442 2083 2087 2053; do
        ss -ntlp | grep -q ":$p " && ports+="$p "
    done
    
    # Check Gaming/BadVPN (Standard Detection + Process Detection)
    for p in 7100 7200 7300; do
        if ss -ntlp | grep -q ":$p " || pgrep -x "badvpn-udpgw" > /dev/null; then
            gaming+="$p "
        fi
    done

    # Check Hysteria and other UDP Protocols
    local udp_ports=""
    for p in 443 36712 53 5300; do
        ss -nulp | grep -q ":$p " && udp_ports+="$p "
    done
    
    [[ ! -z $udp_ports ]] && ports+="${MAGENTA}[UDP:$udp_ports]${NC}"
    
    if [[ ! -z $gaming ]]; then
        # Remove duplicate space and add label
        gaming_clean=$(echo $gaming | xargs)
        echo -e "${ports}${MAGENTA}[UDP:$gaming_clean]${NC}"
    else
        echo -e "$ports"
    fi
}

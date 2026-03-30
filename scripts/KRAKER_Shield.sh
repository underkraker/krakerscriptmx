# Colores de Respaldo
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BARRA="${CYAN}======================================================${NC}"

# Función Interna de Cabecera (Respaldo)
msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${GREEN}    🐲 $1 🐲${NC}"
    echo -e "${BARRA}"
}

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh"

verify_license() {
    msg_header "CENTRO DE VALIDACIÓN KRAKER ELITE"
    echo -e "  ${WHITE}🛡️ PROTECCIÓN ACTIVA - MAESTRO UNDERKRAKER${NC}"
    echo -e "${BARRA}"
    
    # 📝 1. Dominio Maestro Oculto (Cloudflare Optimized)
    LICENSE_DOMAIN="masterbotmx.vpskraker.shop"
    
    # 📝 2. Pedir Key de Instalación
    echo -e -n "  ${YELLOW}🗝️ INGRESE SU KEY DE INSTALACIÓN: ${NC}"
    read USER_KEY
    
    if [[ -z "$USER_KEY" ]]; then
       echo -e "${RED}  ❌ Error: La llave no puede estar vacía.${NC}"
       exit 1
    fi
    
    # 🌐 3. Validar con el Bot (Puerto 8080 para Cloudflare/AWS)
    echo -e "  ${CYAN}[*] Conectando con el Servidor Central...${NC}"
    
    # Curl optimizado: Puerto 8080 atraviesa firewalls mejor que el 5000.
    RESPONSE=$(curl -s --connect-timeout 2 --max-time 4 "http://$LICENSE_DOMAIN:8080/api/validar?key=$USER_KEY")
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    
    if [[ "$STATUS" == "success" ]]; then
        OWNER=$(echo "$RESPONSE" | jq -r '.owner')
        echo -e "  ${GREEN}✅ ACCESO CONCEDIDO: Bienvenido Maestro @$OWNER${NC}"
        mkdir -p /etc/kraker
        echo "$USER_KEY" > /etc/kraker/.license
        sleep 2
        return 0
    else
        echo -e "  ${RED}❌ ACCESO DENEGADO: Key Inválida o Expirada.${NC}"
        echo -e "  ${YELLOW}[!] Contacta a @underkraker para adquirir soporte.${NC}"
        echo -e "${BARRA}"
        exit 1
    fi
}

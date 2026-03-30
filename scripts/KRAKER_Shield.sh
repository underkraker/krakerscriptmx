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
    
    # 📝 1. Dominio Maestro Oculto
    LICENSE_DOMAIN="krakermaster.duckdns.org"
    
    # 📝 2. Pedir Key de Instalación
    echo -e -n "  ${YELLOW}🗝️ INGRESE SU KEY DE INSTALACIÓN: ${NC}"
    read USER_KEY
    
    if [[ -z "$USER_KEY" ]]; then
       echo -e "${RED}  ❌ Error: La llave no puede estar vacía.${NC}"
       exit 1
    fi
    
    # 🌐 3. Validar con el Bot (Detección Automática de IP con Timeouts Rápidos)
    echo -e "  ${CYAN}[*] Conectando con el Servidor Central...${NC}"
    
    # Soporta tanto el subdominio limpio como la URL completa
    [[ "$LICENSE_DOMAIN" != *".duckdns.org"* ]] && LICENSE_DOMAIN="$LICENSE_DOMAIN.duckdns.org"
    
    # Curl optimizado: Si en 2s no conecta o en 4s no termina, falla rápido.
    RESPONSE=$(curl -s --connect-timeout 2 --max-time 4 "http://$LICENSE_DOMAIN:5000/api/validar?key=$USER_KEY")
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    
    if [[ "$STATUS" == "success" ]]; then
        OWNER=$(echo "$RESPONSE" | jq -r '.owner')
        echo -e "  ${GREEN}✅ ACCESO CONCEDIDO: Bienvenido Maestro @$OWNER${NC}"
        echo "$USER_KEY" > /etc/kraker/.license 2>/dev/null || { mkdir -p /etc/kraker; echo "$USER_KEY" > /etc/kraker/.license; }
        sleep 2
        return 0
    else
        echo -e "  ${RED}❌ ACCESO DENEGADO: Key Inválida o Expirada.${NC}"
        echo -e "  ${YELLOW}[!] Contacta a @underkraker para adquirir soporte.${NC}"
        echo -e "${BARRA}"
        exit 1
    fi
}

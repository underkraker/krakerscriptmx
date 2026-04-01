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
    
    # Curl Master Optimizado: Ahora con 10s de margen para evitar fallos por Lag
    echo -e "  ${CYAN}[*] Validando Licencia con el Servidor...${NC}"
    RESPONSE=$(curl -s --connect-timeout 5 --max-time 10 "http://$LICENSE_DOMAIN:8080/api/validar?key=$USER_KEY")
    
    # 🕵️ Verificación de Integridad de Respuesta
    if [[ -z "$RESPONSE" ]]; then
        echo -e "  ${RED}❌ Error: No hay respuesta del Servidor Central.${NC}"
        echo -e "  ${YELLOW}[!] Intente de nuevo en unos segundos.${NC}"
        exit 1
    fi

    STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null || echo "error")
    
    if [[ "$STATUS" == "success" ]]; then
        OWNER=$(echo "$RESPONSE" | jq -r '.owner' 2>/dev/null || echo "Desconocido")
        echo -e "  ${GREEN}✅ ACCESO CONCEDIDO: Bienvenido @$OWNER${NC}"
        mkdir -p /etc/kraker
        echo "$USER_KEY" > /etc/kraker/.license
        sleep 2
        return 0
    else
        echo -e "  ${RED}❌ ACCESO DENEGADO: Key Inválida, Usada o Expirada.${NC}"
        echo -e "  ${YELLOW}[!] Soporte Oficial: @underkraker${NC}"
        echo -e "${BARRA}"
        exit 1
    fi
}

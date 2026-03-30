#!/bin/bash
# KRAKER MASTER - LICENSE SHIELD (ESCRUTINIO DE ELITE) 🐲🛡️🚀
# Versión 1.0 (Dynamic License Engine)

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh"

verify_license() {
    msg_header "CENTRO DE VALIDACIÓN KRAKER ELITE"
    echo -e "  ${WHITE}🛡️ PROTECCIÓN ACTIVA - MAESTRO UNDERKRAKER${NC}"
    echo -e "${BARRA}"
    
    # 📝 1. Pedir Dominio de Licencia (DuckDNS)
    read -p "🦆 Ingrese su Dominio de Licencias DuckDNS: " LICENSE_DOMAIN
    [[ -z "$LICENSE_DOMAIN" ]] && { echo -e "${RED}[!] Dominio Inválido.${NC}"; exit 1; }
    
    # 📝 2. Pedir Key de Instalación
    echo -e -n "  ${YELLOW}🗝️ INGRESE SU KEY DE INSTALACIÓN: ${NC}"
    read USER_KEY
    
    if [[ -z "$USER_KEY" ]]; then
       echo -e "${RED}  ❌ Error: La llave no puede estar vacía.${NC}"
       exit 1
    fi
    
    # 🌐 3. Validar con el Bot (Detección Automática de IP)
    echo -e "  ${CYAN}[*] Conectando con el Servidor Central ($LICENSE_DOMAIN)...${NC}"
    
    # Soporta tanto el subdominio limpio como la URL completa
    [[ "$LICENSE_DOMAIN" != *".duckdns.org"* ]] && LICENSE_DOMAIN="$LICENSE_DOMAIN.duckdns.org"
    
    RESPONSE=$(curl -s "http://$LICENSE_DOMAIN:5000/api/validar?key=$USER_KEY")
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

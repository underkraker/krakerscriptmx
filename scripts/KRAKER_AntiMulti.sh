#!/bin/bash
# KRAKER MASTER - ANTI MULTI-LOGIN (LIMITADOR)
# Detecta y asfixia a los usuarios abusivos que superan su límite

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1
USER_DB="/etc/kraker_users.db"

# Modo Instalador (Manual)
if [[ "$1" != "cron" ]]; then
    msg_header "LIMITADOR DE TRÁFICO (ANTI-ABUSO)"
    echo -e "${YELLOW}[*] Acoplando limitador al Watchdog Global...${NC}"
    
    if ! crontab -l 2>/dev/null | grep -q "KRAKER_AntiMulti.sh cron"; then
        (crontab -l 2>/dev/null; echo "*/2 * * * * bash $SOURCE_DIR/KRAKER_AntiMulti.sh cron > /dev/null 2>&1") | crontab -
    fi
    
    echo -e "${GREEN}✔ SISTEMA ANTI-MULTILOGIN ACTIVADO EXITOSAMENTE!${NC}"
    echo -e "${CYAN}El Guardián ahora revisará y matará conexiones clonadas cada 2 minutos.${NC}"
    echo -e "${BARRA}"
    sleep 3
    exit 0
fi

# Modo Ejecución (Cron Daemon)
[[ ! -f "$USER_DB" ]] && exit 0

while IFS='|' read -r user pass exp uuid limit; do
    # Evitar lineas vacias o corruptas
    [[ -z "$user" || -z "$limit" ]] && continue
    
    # Contar cuantas sesiones de dropbear/sshd tiene activas el usuario (pidiendo a ps)
    sesiones=$(ps -u "$user" -o comm= 2>/dev/null | grep -E "(dropbear|sshd)" | wc -l)
    
    # Tolerancia: dropbear a veces genera 2 subprocesos por conexión, 
    # por lo que el límite real es (limit * 2). Para ser justos, si hay más, lo matamos todo.
    limite_real=$((limit * 2))
    
    if [[ "$sesiones" -gt "$limite_real" ]]; then
        # Ejecutar purga de criminal
        pkill -u "$user" 2>/dev/null
    fi
done < "$USER_DB"

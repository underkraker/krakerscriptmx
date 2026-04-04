#!/bin/bash
# KRAKER MASTER - EL GUARDIÁN (WATCHDOG)
# Versión 4.5 Supreme Edition

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="/var/log/kraker_guardian.log"
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

check_and_restart() {
    local service=$1
    local cmd_check=$2
    local restart_cmd=$3
    
    if ! eval "$cmd_check" > /dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [!] SERVICIO CAÍDO: $service. Reiniciando..." >> $LOG_FILE
        eval "$restart_cmd" >> $LOG_FILE 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [✔] SERVICIO RESTAURADO: $service" >> $LOG_FILE
    fi
}

# --- Guardian Master List ---

# 1. Xray (VLESS, VMess, Trojan, Reality)
check_and_restart "Xray-core" "pgrep -x xray" "systemctl restart xray"

# 2. Dropbear
check_and_restart "Dropbear" "pgrep -x dropbear" "systemctl restart dropbear"

# 3. OpenSSH
check_and_restart "SSH Server" "pgrep -x sshd" "systemctl restart ssh"

# 4. KRAKER SSL Gateway (Stunnel4 Nativo)
# El gateway en Python fue desactivado por baja velocidad (conservado comentado abajo)
# if screen -list | grep -q "SSL_Gateway"; then
#     : # OK
# else
#     if [[ -f "/etc/ws_ssl/config" ]]; then
#         source "/etc/ws_ssl/config"
#         echo "[$(date '+%Y-%m-%d %H:%M:%S')] [!] GATEWAY SSL CAÍDO. Restaurando..." >> $LOG_FILE
#         screen -dmS SSL_Gateway python3 "$SOURCE_DIR/KRAKER_SSL_Gateway.py" "$LPORT" "/etc/ws_ssl/server.crt" "/etc/ws_ssl/server.key" "127.0.0.1" "$BPORT"
#     fi
# fi
check_and_restart "Stunnel4 SSL Gateway" "pgrep -x stunnel4" "stunnel4 /etc/stunnel/kraker.conf"

# 5. BadVPN (UDP Gaming) - Modern Systemd Monitoring
if systemctl is-active --quiet kraker-udp; then
    : # OK
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [!] UDP GAMING (systemd) CAÍDO. Restaurando..." >> $LOG_FILE
    systemctl restart kraker-udp >> $LOG_FILE 2>&1
    
    # Fallback por si el servicio no existe o falla catastróficamente
    if ! systemctl is-active --quiet kraker-udp; then
        if ! pgrep -x badvpn-udpgw > /dev/null 2>&1; then
             echo "[$(date '+%Y-%m-%d %H:%M:%S')] [!] EMERGENCIA: Reiniciando binario BadVPN directamente..." >> $LOG_FILE
             screen -dmS UDP_Gaming badvpn-udpgw --listen-addr 0.0.0.0:7300 --max-clients 500
        fi
    fi
fi

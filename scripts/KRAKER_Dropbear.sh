#!/bin/bash
# KRAKER MASTER - DROPBEAR SSH (v2.1 Elite)
# El servidor SSH ligero por excelencia para Inyectores

# Cargar Librerías
SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

# 1. Instalar Dropbear
msg_header "DROPBEAR SSH SETUP"
install_deps dropbear coreutils ufw lsof

# 2. Configurar Puertos (80, 143, 442)
echo -e "${YELLOW}[*] Asegurando Puerto 80 para KRAKER MASTER...${NC}"

# 1. Liberar puerto 80 agresivamente
systemctl stop apache2 nginx lighttpd > /dev/null 2>&1
fuser -k 80/tcp > /dev/null 2>&1

# 2. Desactivar el socket de Dropbear que causa conflictos en Ubuntu 24.04
systemctl stop dropbear.socket > /dev/null 2>&1
systemctl disable dropbear.socket > /dev/null 2>&1

# 3. Configurar Dropbear (Puerto 80 como Principal)
cat << EOF > /etc/default/dropbear
# KRAKER MASTER - Dropbear Config
NO_START=0
DROPBEAR_PORT=80
DROPBEAR_EXTRA_ARGS="-p 143 -p 442"
DROPBEAR_BANNER="/etc/motd"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

# 4. Finalización
setup_motd
echo -e "${YELLOW}[*] Reiniciando y abriendo Firewall...${NC}"
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 143/tcp > /dev/null 2>&1
ufw allow 442/tcp > /dev/null 2>&1

systemctl daemon-reload
systemctl enable dropbear > /dev/null 2>&1
systemctl restart dropbear > /dev/null 2>&1

msg_header "DROPBEAR INSTALACIÓN COMPLETADA"
echo -e "${GREEN}✔ KRAKER DROPBEAR INSTALADO CON ÉXITO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}PUERTOS ACTIVOS:${NC}"
echo -e "${CYAN}Puerto 80   : ${NC}ACTIVO (Ideal para WSS/Payload)"
echo -e "${CYAN}Puerto 143  : ${NC}ACTIVO (Fijo)"
echo -e "${CYAN}Puerto 442  : ${NC}ACTIVO (Fijo)"
echo -e "${BARRA}"
echo -e "${YELLOW}RECUERDA: Abre los puertos en tu consola de Cloud (AWS/GCP/Azure).${NC}"
echo -e "${BARRA}"

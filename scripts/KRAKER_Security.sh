#!/bin/bash
# KRAKER MASTER - SECURITY & FAIL2BAN
# Escudo Anti-Fuerza Bruta para puertos SSH/Dropbear

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

msg_header "ESCUDO FAIL2BAN (ANTI-ATAQUES)"

echo -e "${YELLOW}[*] Instalando Fail2Ban...${NC}"
install_deps fail2ban iptables ufw

cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
ignoreip = 127.0.0.1/8
bantime  = 3600
findtime  = 600
maxretry = 3
banaction = iptables-multiport

[sshd]
enabled = true
port    = 22,80,143,442
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[dropbear]
enabled = true
port     = 22,80,143,442
logpath  = /var/log/auth.log
maxretry = 3
EOF

echo -e "${YELLOW}[*] Reiniciando servicio de seguridad...${NC}"
systemctl restart fail2ban > /dev/null 2>&1
systemctl enable fail2ban > /dev/null 2>&1

echo -e "${GREEN}✔ ESCUDO FAIL2BAN ACTIVADO EXITOSAMENTE!${NC}"
echo -e "${CYAN}Cualquier atacante que falle 3 contraseñas seguidas en ssh/dropbear será bloqueado por 1 hora.${NC}"
echo -e "${BARRA}"
sleep 3

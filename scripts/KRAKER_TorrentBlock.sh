#!/bin/bash
# KRAKER MASTER - BLOQUEO P2P (Torrent & DMCA Shield)
# Protege a la VPS de quejas de Copyright bloqueando trackers

SOURCE_DIR=$(dirname "$(readlink -f "$0")")
[[ -f "$SOURCE_DIR/utils.sh" ]] && source "$SOURCE_DIR/utils.sh" || exit 1

msg_header "ESCUDO ANTI-TORRENT (P2P BLOCK)"

echo -e "${YELLOW}[*] Instalando dependencias del Firewall (Iptables String Match)...${NC}"
install_deps iptables ufw

echo -e "${YELLOW}[*] Asignando reglas de rastreo L7 a iptables...${NC}"

# Borramos reglas anteriores si existen
iptables -D FORWARD -m string --algo bm --string "BitTorrent" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "peer_id=" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string ".torrent" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "torrent" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "announce" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "info_hash" -j DROP > /dev/null 2>&1
iptables -D FORWARD -m string --algo bm --string "get_peers" -j DROP > /dev/null 2>&1

# Aplicar las Reglas nuevas
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables -A FORWARD -m string --algo bm --string "get_peers" -j DROP

# Instalar persitencia
echo -e "${YELLOW}[*] Guardando Firewall para que persista tras reiniciar...${NC}"
install_deps iptables-persistent 
netfilter-persistent save > /dev/null 2>&1

echo -e "${GREEN}✔ ESCUDO DMCA (ANTI-TORRENT) ACTIVADO EXITOSAMENTE!${NC}"
echo -e "${CYAN}Si algún cliente abre una app de Torrent, su descarga permanecerá en 0KB/s infinito.${NC}"
echo -e "${BARRA}"
sleep 3

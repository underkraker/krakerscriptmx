import os

def redesign():
    path = 'menu.sh'
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    # Define the new UI components
    # 1. Header with Stats
    header_code = [
        'function header() {\n',
        '    clear\n',
        '    export LC_ALL=C.UTF-8\n',
        '    local P_NAME="KRAKER MASTER"\n',
        '    [ -f /etc/gaming_vps/panel_name.txt ] && P_NAME=$(cat /etc/gaming_vps/panel_name.txt | tr "[:lower:]" "[:upper:]")\n',
        '    \n',
        '    # Obtener IP Pública (Cache por sesión)\n',
        '    if [ -z "$MY_IP" ]; then MY_IP=$(curl -s4 icanhazip.com || hostname -I | awk "{print $1}"); fi\n',
        '    \n',
        '    # Obtener RAM y CPU\n',
        '    ram_total=$(free -m | awk "/Mem:/ {print $2}")\n',
        '    ram_used=$(free -m | awk "/Mem:/ {print $3}")\n',
        '    ram_perc=$((ram_used * 100 / ram_total))\n',
        '    cpu_load=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\\([0-9.]*\\)%* id.*/\\1/" | awk "{print 100 - $1}")\n',
        '    cpu_perc=${cpu_load%.*}\n',
        '    \n',
        '    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"\n',
        '    echo -e "${MAGENTA}${BOLD}                ⚡ $P_NAME ⚡${NC}"\n',
        '    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"\n',
        '    echo -e "   ${WHITE}🌍 IP: ${NC}${CYAN}$MY_IP${NC}"\n',
        '    echo -e "   ${WHITE}💾 Mem. RAM  : $(draw_bar $ram_perc)  ${ram_perc}% ${ram_used}MB / ${ram_total}MB${NC}"\n',
        '    echo -e "   ${WHITE}🧠 Uso CPU   : $(draw_bar $cpu_perc)  ${cpu_perc}%${NC}"\n',
        '    \n',
        '    # Detector de Puertos Activos\n',
        '    echo -ne "   ${WHITE}🔒 Puertos Activos: ${YELLOW}"\n',
        '    for p in 22 80 443 7300 8080 3128 8081 444 53; do\n',
        '        if ss -tuln | grep -q ":$p "; then\n',
        '            case $p in 22) echo -n "22(SSH) ";; 80) echo -n "80(Drop) ";; 443) echo -n "443(SSL) ";; 7300) echo -n "7300(UDP) ";; 8081) echo -n "8081(WS) ";; 53) echo -n "53(DNS) ";; esac\n',
        '        fi\n',
        '    done\n',
        '    echo -e "${NC}"\n',
        '    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"\n',
        '}\n'
    ]

    # 2. Main Menu with autorefresh
    main_menu_code = [
        'function main_menu() {\n',
        '    while true; do\n',
        '        header\n',
        '        echo -e "   ${MAGENTA}${BOLD}          🏆 M E N Ú   P R I N C I P A L 🏆${NC}\\n"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}👤 Gestor de Usuarios VIP${NC}"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🚀 Acelerador y Optimización de Red${NC}"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}⚙️  Instalador de Protocolos y Túneles${NC}"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 4 ${CYAN}]${NC} ${BOLD}📊 Monitor de Recursos (RAM/CPU/Ping)${NC}"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 5 ${CYAN}]${NC} ${BOLD}🛡️  Módulo de Seguridad y Anti-Abusos${NC}"\n',
        '        echo -e "      ${CYAN}[${YELLOW} 6 ${CYAN}]${NC} ${BOLD}🛠️  Herramientas de Sistema (DNS/Swap)${NC}\\n"\n',
        '        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"\n',
        '        echo -e "    ${CYAN}[${YELLOW} 98${CYAN}]${NC} ${WHITE}🔄 Actualizar Script   ${CYAN}[${YELLOW} 99${CYAN}]${NC} ${WHITE}🗑️ Desinstalar Script${NC}"\n',
        '        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"\n',
        '        \n',
        '        read -t 5 -p "   🎮 Selecciona una opción (Autorefresco 5s): " opt\n',
        '        [ -z "$opt" ] && continue\n',
        '\n',
        '        case $opt in\n',
        '            1) users_menu ;;\n',
        '            2) optimizer_menu ;;\n',
        '            3) services_menu ;;\n',
        '            4) monitor_menu ;;\n',
        '            5) security_menu ;;\n',
        '            6) tools_menu ;;\n',
        '            98) update_script ;;\n',
        '            99) uninstall_script ;;\n',
        '            *) echo -e "${RED}[x] Opción inválida."; sleep 1 ;;\n',
        '        esac\n',
        '    done\n',
        '}\n'
    ]

    # Substitutions
    # 22-48 (Header)
    # 1179-1221 approx (Main Menu)
    # 654-688 (Services Menu)
    # etc...
    
    # We will do a generic replacement of functions based on their names
    def replace_func(func_name, new_lines):
        nonlocal lines
        start_idx = -1
        for i, line in enumerate(lines):
            if f"function {func_name}() {{" in line:
                start_idx = i
                break
        if start_idx == -1: return
        
        # Find the closing brace
        brace_count = 0
        end_idx = -1
        for i in range(start_idx, len(lines)):
            brace_count += lines[i].count('{')
            brace_count -= lines[i].count('}')
            if brace_count == 0 and i > start_idx:
                end_idx = i
                break
        
        if end_idx != -1:
            lines[start_idx:end_idx+1] = new_lines

    replace_func('header', header_code)
    replace_func('main_menu', main_menu_code)
    
    # Simple formatting for other menus
    for func in ['services_menu', 'optimizer_menu', 'users_menu', 'monitor_menu', 'security_menu', 'tools_menu']:
        # We just want to make sure they use 'header' first (they already do)
        pass

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print("UI Redesign complete")

if __name__ == "__main__":
    redesign()

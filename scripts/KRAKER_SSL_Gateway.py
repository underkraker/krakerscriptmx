#!/usr/bin/python3
# -*- coding: utf-8 -*-
# KRAKER VPS - SSL GATEWAY (DUAL MODE: WS + DIRECT)
# Versión Avanzada 2.0 con Detección Automática
# Target: Forward to Port 80

import socket, threading, ssl, sys, select, time

# Configuración KRAKER MASTER
BUFFER_SIZE = 16384
HANDSHAKE_TIMEOUT = 1.0 # Mayor tiempo para conexiones lentas

# Respuesta Handshake WebSocket
WS_RESPONSE = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"

def transfer(src, dst):
    """Bomba de datos bidireccional de alto rendimiento."""
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data: break
            dst.sendall(data)
    except:
        pass
    finally:
        for s in [src, dst]:
            try: s.shutdown(socket.SHUT_RDWR)
            except: pass
            try: s.close()
            except: pass

def handler(newsock, addr, context, target_addr, target_port):
    """Manejo individual de conexión (SSL + Detección + Puente)."""
    try:
        # 1. Envolver en SSL (dentro del hilo para no bloquear a otros)
        client_socket = context.wrap_socket(newsock, server_side=True)
        client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        
        # 2. Peeking Inteligente (Sin sleep bloqueante)
        # Esperamos hasta 1 segundo por el primer paquete (Payload/Handshake)
        r, _, _ = select.select([client_socket], [], [], 1.0)
        
        is_websocket = False
        data = b""
        if r:
            try:
                data = client_socket.recv(BUFFER_SIZE)
                if data and any(data.startswith(m) for m in [b"GET", b"POST", b"CONNECT", b"HEAD"]):
                    is_websocket = True
                    client_socket.sendall(WS_RESPONSE.encode())
            except:
                pass

        # 3. Conexión al Backend (SSH/Dropbear)
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        remote_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        remote_socket.settimeout(5.0)
        
        try:
            remote_socket.connect((target_addr, int(target_port)))
            remote_socket.settimeout(None)
        except:
            client_socket.close()
            return

        # 4. Forwarding de datos iniciales
        if data and not is_websocket:
            remote_socket.sendall(data)

        # 5. Iniciar Puente Bidireccional
        threading.Thread(target=transfer, args=(client_socket, remote_socket), daemon=True).start()
        transfer(remote_socket, client_socket)
        
    except:
        try: newsock.close()
        except: pass

def server(listen_port, cert_file, key_file, target_addr, target_port):
    """Servidor Maestro SSL Asíncrono."""
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(certfile=cert_file, keyfile=key_file)
    context.options |= ssl.OP_NO_SSLv2 | ssl.OP_NO_SSLv3
    
    bind_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    bind_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    bind_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    bind_socket.bind(('', int(listen_port)))
    bind_socket.listen(512)
    
    print(f"[*] KRAKER MASTER SSL Gateway (v3.9) activo en puerto {listen_port}")
    print(f"[*] Estabilidad Máxima - Redirección a {target_addr}:{target_port}")

    while True:
        try:
            newsock, addr = bind_socket.accept()
            # Lanzamos el hilo INMEDIATAMENTE antes del wrap_socket SSL
            threading.Thread(target=handler, args=(newsock, addr, context, target_addr, target_port), daemon=True).start()
        except KeyboardInterrupt:
            break
        except Exception:
            continue

if __name__ == '__main__':
    if len(sys.argv) < 6:
        print("Uso: python3 KRAKER_SSL_Gateway.py <port> <cert> <key> <target_addr> <target_port>")
        sys.exit(1)
    server(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

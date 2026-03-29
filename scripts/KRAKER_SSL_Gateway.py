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
    """Bomba de datos bidireccional con manejo de errores."""
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data: break
            dst.sendall(data)
    except:
        pass
    finally:
        try: src.shutdown(socket.SHUT_RDWR)
        except: pass
        try: src.close()
        except: pass
        try: dst.shutdown(socket.SHUT_RDWR)
        except: pass
        try: dst.close()
        except: pass

def handler(client_socket, target_addr, target_port):
    """Procesador de conexiones con detección inteligente de WebSocket."""
    try:
        # Configuración de rendimiento (Ultra-Low Latency)
        client_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        
        # Detección Proactiva de Payload/WS
        client_socket.setblocking(False)
        time.sleep(HANDSHAKE_TIMEOUT)
        
        is_websocket = False
        try:
            data = client_socket.recv(BUFFER_SIZE)
            if data:
                # Si detectamos una cabecera HTTP, respondemos con 101
                if any(data.startswith(m) for m in [b"GET", b"POST", b"CONNECT", b"HEAD"]):
                    is_websocket = True
                    client_socket.sendall(WS_RESPONSE.encode())
                    # Los datos después del GET suelen ser nulos, pero si existen
                    # se enviarán al backend más adelante.
        except BlockingIOError:
            data = b""

        client_socket.setblocking(True)

        # Conexión al Backend
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        remote_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        remote_socket.settimeout(5.0) # Tiempo de gracia para conectar
        
        try:
            remote_socket.connect((target_addr, int(target_port)))
            remote_socket.settimeout(None) # Ilimitado para la transferencia
        except:
            client_socket.close()
            return

        # SIEMPRE enviar los datos residuales al backend si existen
        # (Importante para no perder el inicio del handshake SSH)
        if data and not is_websocket:
            remote_socket.sendall(data)

        # Hilos de transferencia
        threading.Thread(target=transfer, args=(client_socket, remote_socket), daemon=True).start()
        transfer(remote_socket, client_socket)
        
    except:
        pass
    finally:
        try: client_socket.close()
        except: pass

def server(listen_port, cert_file, key_file, target_addr, target_port):
    """Servidor Maestro SSL."""
    context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    context.load_cert_chain(certfile=cert_file, keyfile=key_file)
    context.options |= ssl.OP_NO_SSLv2 | ssl.OP_NO_SSLv3 # Seguridad reforzada
    context.options |= ssl.OP_NO_SSLv2 | ssl.OP_NO_SSLv3
    
    bind_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    bind_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    bind_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    bind_socket.bind(('', int(listen_port)))
    bind_socket.listen(512)
    
    print(f"[*] KRAKER MASTER SSL Gateway activo en puerto {listen_port}")
    print(f"[*] Redirigiendo a {target_addr}:{target_port}")

    while True:
        try:
            newsock, addr = bind_socket.accept()
            ssl_sock = context.wrap_socket(newsock, server_side=True)
            threading.Thread(target=handler, args=(ssl_sock, target_addr, target_port), daemon=True).start()
        except Exception:
            continue

if __name__ == '__main__':
    if len(sys.argv) < 6:
        print("Uso: python3 KRAKER_SSL_Gateway.py <port> <cert> <key> <target_addr> <target_port>")
        sys.exit(1)
    server(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

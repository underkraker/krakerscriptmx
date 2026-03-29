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
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data: break
            dst.sendall(data)
    except: pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handler(client_socket, address, target_addr, target_port):
    try:
        # Detectar WebSocket/Payload
        client_socket.setblocking(False)
        time.sleep(HANDSHAKE_TIMEOUT)
        
        is_websocket = False
        try:
            data = client_socket.recv(BUFFER_SIZE)
            if data:
                if any(data.startswith(m) for m in [b"GET", b"POST", b"CONNECT", b"HEAD"]):
                    is_websocket = True
                    client_socket.sendall(WS_RESPONSE.encode())
                # Si no es WS, guardamos los datos para enviarlos al backend
        except BlockingIOError:
            data = b""

        client_socket.setblocking(True)

        # Conectar al Backend (SSH/Dropbear)
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.settimeout(3.0)
        try:
            remote_socket.connect((target_addr, int(target_port)))
        except Exception as e:
            # Si el backend falla, cerramos la conexión del cliente
            client_socket.close()
            return

        # Si teníamos datos iniciales (no WS), los enviamos
        if data and not is_websocket:
            remote_socket.sendall(data)

        # Iniciar Puente
        threading.Thread(target=transfer, args=(client_socket, remote_socket), daemon=True).start()
        transfer(remote_socket, client_socket)

    except:
        pass

def main(port, cert, key, target_addr, target_port):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=cert, keyfile=key)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind(('0.0.0.0', int(port)))
        server.listen(1000)
        secure_server = context.wrap_socket(server, server_side=True)
        print(f"[*] KRAKER MASTER - Gateway Dual Activo en Puerto {port}")
        print(f"[*] Destino: {target_addr}:{target_port}")
        
    except Exception as e:
        print(f"[!] Error: {e}")
        sys.exit(1)

    while True:
        try:
            client, addr = secure_server.accept()
            threading.Thread(target=handler, args=(client, addr, target_addr, target_port), daemon=True).start()
        except:
            pass

if __name__ == '__main__':
    if len(sys.argv) < 6:
        print("Uso: python3 KRAKER_SSL_Gateway.py <port> <cert> <key> <target_addr> <target_port>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

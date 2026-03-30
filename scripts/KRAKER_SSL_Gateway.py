#!/usr/bin/python3
# -*- coding: utf-8 -*-
# KRAKER VPS - SSL GATEWAY (DUAL MODE: WS + DIRECT)
# Versión Avanzada 2.0 con Detección Automática
# Target: Forward to Port 80

import socket, ssl, threading, time, sys

BUFFER_SIZE = 8192
HANDSHAKE_TIMEOUT = 1.0
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

def handler(client_socket, target_addr, target_port):
    try:
        # Optimización: Reducir latencia de detección (Eliminar sleep inútil)
        client_socket.settimeout(0.3)
        is_websocket = False
        data = b""
        try:
            data = client_socket.recv(BUFFER_SIZE)
            if data:
                if any(data.startswith(m) for m in [b"GET", b"POST", b"CONNECT", b"HEAD"]):
                    is_websocket = True
                    client_socket.sendall(WS_RESPONSE.encode())
        except:
            # Si no hay datos inmediatos, asumimos Direct SSL
            pass
        client_socket.settimeout(None)

        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.settimeout(5.0)
        try:
            remote_socket.connect((target_addr, int(target_port)))
            remote_socket.settimeout(None)
        except:
            client_socket.close()
            return

        if data and not is_websocket:
            remote_socket.sendall(data)

        threading.Thread(target=transfer, args=(client_socket, remote_socket), daemon=True).start()
        transfer(remote_socket, client_socket)
    except: pass
    finally:
        try: client_socket.close()
        except: pass

def main(port, cert, key, target_addr, target_port):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=cert, keyfile=key)
    
    # Bug corregido: Inicializar el socket 'server'
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        server.bind(('0.0.0.0', int(port)))
        server.listen(500)
        # Optimización Turbo: Desactivar Algoritmo de Nagle
        server.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        print(f"[*] KRAKER MASTER - Gateway v4.5 [Turbo Gaming] Activo en Puerto {port}")
    except Exception as e:
        print(f"[!] Error: {e}")
        sys.exit(1)

    while True:
        raw_client = None
        try:
            raw_client, addr = server.accept()
            # Envolver el socket de cliente individualmente para mayor estabilidad
            client = context.wrap_socket(raw_client, server_side=True)
            threading.Thread(target=handler, args=(client, target_addr, target_port), daemon=True).start()
        except Exception as e:
            # Optimización Master: Evitar que el proceso consuma 100% CPU en caso de error crítico
            time.sleep(1)
            if raw_client:
                try: raw_client.close()
                except: pass

if __name__ == '__main__':
    if len(sys.argv) < 6:
        print("Uso: python3 KRAKER_SSL_Gateway.py <port> <cert> <key> <target_addr> <target_port>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])

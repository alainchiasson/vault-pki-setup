#!/usr/bin/python3
import time

import socket
import ssl

host_addr = 'server'
host_port = 8082
server_sni_hostname = 'server'
server_cert = 'common.cert.pem'
client_cert = 'client.cert.pem'
client_key = 'client.key.pem'

while True:
    context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH, cafile=server_cert)
    context.load_cert_chain(certfile=client_cert, keyfile=client_key)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        conn = context.wrap_socket(s, server_side=False, server_hostname=server_sni_hostname)
        conn.connect((host_addr, host_port))
        print("SSL established. Peer: {}".format(conn.getpeercert()))
        print("Sending: 'Hello, world!")
        conn.sendall(b"Hello, world!")

        # Get message echoed back
        data = conn.recv(1024)

    print(f"Received {data!r}" )

    print("Sleeping 30 seconds")
    time.sleep(30)

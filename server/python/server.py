#!/usr/bin/python3

import sys
import socket
from socket import AF_INET, SOCK_STREAM, SO_REUSEADDR, SOL_SOCKET, SHUT_RDWR
import ssl

listen_addr = '0.0.0.0'
listen_port = 8082
server_cert = 'server.cert.pem'
server_key = 'server.key.pem'
client_certs = 'common.cert.pem'

context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
context.verify_mode = ssl.CERT_REQUIRED
context.load_cert_chain(certfile=server_cert, keyfile=server_key)
context.load_verify_locations(cafile=client_certs)

bindsocket = socket.socket()
bindsocket.bind((listen_addr, listen_port))
bindsocket.listen()

while True:
    print("Waiting for client")
    newsocket, fromaddr = bindsocket.accept()

    with newsocket:
        print("Client connected: {}:{}".format(fromaddr[0], fromaddr[1]))

        conn = context.wrap_socket(newsocket, server_side=True)
        cert = conn.getpeercert()
        
        print("SSL established. Peer: {}".format(cert))        
        print("SubjectName: {}".format(cert['subject'][0][0][1]))
        
        while True:
            data = conn.recv(1024)
            if not data: 
                break
            conn.sendall(data)
        


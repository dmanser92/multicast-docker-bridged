#!/usr/bin/env python
import socket
import struct

MULTICAST_GROUP = '225.1.2.3'
PORT = 5000

# Create a UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.bind(('', PORT))

# Tell the kernel to add the socket to the multicast group on all interfaces
mreq = struct.pack("4sl", socket.inet_aton(MULTICAST_GROUP), socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

print(f"Listening for multicast messages on {MULTICAST_GROUP}:{PORT}")
while True:
    data, addr = sock.recvfrom(1024)
    try:
        message = data.decode()
    except UnicodeDecodeError:
        message = data
    print(f"Received message from {addr}: {message}")

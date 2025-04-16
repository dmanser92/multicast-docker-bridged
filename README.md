# multicast-docker-bridged

For now, this is a working proof-of-concept (POC) that demonstrates forwarding of multicast UDP packets from a host interface to an isolated Docker container using SMCRoute. I'm looking for a good option to work around docker's lack of multicast support in bridged networks without having to use host networking. I also want to avoid macvlan as additional interfaces in the physical network complicate things.

If I end up using this in production, I could see myself doing the following things next:
- Build a docker image for everyone to enjoy from mcast-proxy
- Support automatic interface detection if a target container is configured
- Support dynamic IGMP group joining

1. **proxy Container:**  
   Runs the SMCRoute daemon with the host network and forwards incoming multicast packets from a specified WiFi interface (e.g. `wlp0s20f3`) to a fixed IP in a custom Docker network.

2. **Client Container:**  
   Runs a simple Python script that listens on UDP port 5000 and prints any received multicast packets. This container is attached to an isolated Docker bridge network

## Project Structure
```
.
├── README.md                 # This README
├── docker-compose.yml        # The compose project file
├── mcast-client              # Dockerfile and listen script for evaluating the proxy
│   ├── Dockerfile
│   └── listen.py
└── mcast-proxy               # Dockerfile, entrypoint and smcroute configuration for the proxy
    ├── Dockerfile
    ├── entrypoint.sh
    └── smcroute.conf
```

## How It Works

- **SMCRoute Configuration:**  
  The `smcroute.conf` file instructs SMCRoute to:
  - Enable the physical interfaces (`enp4s0`, `br-4a1a84447cc4`).
  - Join the multicast group `225.1.2.3` on the specified interfaces.
  - Forward any multicast packets received on that group to the other interface (2-way).

- **Client Listener:**  
  The `listen.py` Python script binds to UDP port 5000, joins the multicast group `225.1.2.3`, and prints out any received messages. Note that the script is run in unbuffered mode to immediately print log messages.

- **Docker Networking:**  
  The mcast-proxy container runs in host network mode (so it sees the actual host interfaces) while the client container runs in an isolated network (bridged).

## Prerequisites
- Docker and Docker Compose installed on your host system.
- A physical interface (e.g., `wlp0s20f3`) that supports multicast traffic.
- Basic command-line knowledge to run Docker commands.
- Optional: `netcat` (or similar) to send test multicast packets from the host.

## Setup
1. **Clone the Repository:**  
   Clone or copy the project files into a working directory on your host system.

2. **Customize Configuration (Optional):**  
   - Change the interface names of the host and container interfaces to matches what is specified in the `smcroute.conf` file.

3. **Build and Start the Containers:**  
   Run the following command from the project root directory:
   ```bash
   docker-compose up --build
   ```

## How to test
You can run this command inside of the client container or outside somewhere on the same physical network:
```sh
echo "Test multicast message" | nc -u -b 225.1.2.3 5000 -q 1 -M 2
```

## What we need to configure on the host
```sh
# Increasing ttl of incoming multicast packets on enp4s0 to 225.1.2.3 by one so they don't get dropped
iptables -t mangle -A PREROUTING -d 225.1.2.3 -j TTL --ttl-inc 1
# Accept forwarding of multicast packets for 225.1.2.3 -> host to container works now
iptables -I FORWARD 1 -d 225.1.2.3 -j ACCEPT
# Allow forwarding IGMP packets
iptables -A FORWARD -p igmp -j ACCEPT

# These might be necessary
# sudo sysctl -w net.ipv4.conf.br-4a1a84447cc4.rp_filter=0
# sudo sysctl -w net.ipv4.conf.enp4s0.rp_filter=0
```

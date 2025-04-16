#!/bin/bash

set -euo pipefail

function iptables_setup() {
    # Enable multicast routing/forwarding by increasing the TTL
    # This is needed to allow multicast packets to be forwarded from the host to the container
    iptables -t mangle -A PREROUTING -d 225.1.2.3 -j TTL --ttl-inc 1
    # Accept forwarding of multicast packets for 225.1.2.3 -> host to container works now
    iptables -I FORWARD 1 -d 225.1.2.3 -j ACCEPT
    # Allow forwarding IGMP packets
    iptables -A FORWARD -p igmp -j ACCEPT
}

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi
if ! command -v iptables &> /dev/null; then
  echo "iptables could not be found, please install it first" 1>&2
  exit 1
fi

iptables_setup

if [[ $# -eq 0 ]]; then
  exec smcrouted -N -n -f /etc/smcroute.conf
fi

exec "$@"

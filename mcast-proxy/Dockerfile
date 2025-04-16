FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    smcroute \
    iproute2 \
    iputils-ping \
    tcpdump \
    net-tools \
    iputils-tracepath \
    netcat-openbsd \
    iptables \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["smcrouted", "-N", "-n", "-f", "/etc/smcroute.conf"]

FROM python:3.13-slim

WORKDIR /app
RUN apt-get update && apt-get install -y \
    iproute2 \
    iputils-ping \
    tcpdump \
    net-tools \
    iputils-tracepath \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY listen.py .

CMD ["python", "-u", "listen.py"]

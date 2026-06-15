FROM debian:trixie-slim

RUN apt update && apt install -y \
    curl gnupg lsb-release \
    procps iproute2 iputils-ping \
    && curl -s https://deb.frrouting.org/frr/keys.gpg \
       | tee /usr/share/keyrings/frrouting.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" \
       > /etc/apt/sources.list.d/frr.list \
    && apt update && apt install -y frr frr-pythontools \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons && \
    sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons

CMD ["/bin/bash", "-c", "/usr/lib/frr/frrinit.sh start && tail -f /dev/null"]

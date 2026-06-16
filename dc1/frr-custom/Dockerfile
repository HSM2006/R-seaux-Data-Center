FROM debian:trixie-slim

RUN apt update && apt install -y \
    curl gnupg lsb-release \
    procps iproute2 iputils-ping tcpdump \
    && curl -s https://deb.frrouting.org/frr/keys.gpg \
       | tee /usr/share/keyrings/frrouting.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" \
       > /etc/apt/sources.list.d/frr.list \
    && apt update && apt install -y frr frr-pythontools \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Activer les daemons nécessaires
RUN sed -i 's/^bgpd=no/bgpd=yes/'   /etc/frr/daemons && \
    sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons && \
    sed -i 's/^bfdd=no/bfdd=yes/'   /etc/frr/daemons && \
    echo 'service integrated-vtysh-config' > /etc/frr/vtysh.conf

# Entrypoint qui démarre FRR proprement (sans watchfrr) + ip_forward
COPY docker-start.sh /usr/lib/frr/docker-start.sh
RUN chmod +x /usr/lib/frr/docker-start.sh

CMD ["/usr/lib/frr/docker-start.sh"]

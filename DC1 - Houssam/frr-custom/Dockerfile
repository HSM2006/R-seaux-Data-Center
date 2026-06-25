FROM debian:trixie-slim

# Empecher Debian de demarrer les services pendant apt install
# (sinon snmpd demarre et squatte le port 161 dans le container)
RUN echo "exit 101" > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

RUN apt update && apt install -y \
    curl gnupg lsb-release \
    procps iproute2 iputils-ping tcpdump \
    snmpd snmp iperf3 \
    && curl -s https://deb.frrouting.org/frr/keys.gpg \
       | tee /usr/share/keyrings/frrouting.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" \
       > /etc/apt/sources.list.d/frr.list \
    && apt update && apt install -y frr frr-pythontools \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Module SNMP de FRR (BGP4-MIB / OSPF-MIB via AgentX) — best-effort :
# si le paquet n'existe pas pour cette version, l'image se construit quand
# même (les compteurs IF-MIB via snmpd restent disponibles).
RUN apt update && (apt install -y frr-snmp || echo "frr-snmp indisponible : IF-MIB uniquement") \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Activer les daemons nécessaires
RUN sed -i 's/^bgpd=no/bgpd=yes/'   /etc/frr/daemons && \
    sed -i 's/^ospfd=no/ospfd=yes/' /etc/frr/daemons && \
    sed -i 's/^bfdd=no/bfdd=yes/'   /etc/frr/daemons && \
    echo 'service integrated-vtysh-config' > /etc/frr/vtysh.conf

# snmpd.conf custom : rocommunity public SANS restriction de vue (-V systemonly)
# Le défaut Debian ne donne accès qu'au system MIB → IF-MIB et BGP4-MIB vides
COPY snmpd.conf /etc/snmp/snmpd.conf

# Entrypoint qui démarre FRR proprement (sans watchfrr) + ip_forward
COPY docker-start.sh /usr/lib/frr/docker-start.sh
RUN chmod +x /usr/lib/frr/docker-start.sh

CMD ["/usr/lib/frr/docker-start.sh"]

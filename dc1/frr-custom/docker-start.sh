#!/bin/bash
# Démarrage FRR pour conteneurs Containerlab (SAE DevCloud 4D01)
# Évite watchfrr (qui bloque dans les conteneurs) : daemons lancés à la main + vtysh -b
set +e

mkdir -p /var/run/frr
chown -R frr:frr /var/run/frr 2>/dev/null || true

# IP forwarding — INDISPENSABLE : les spines routent le transport VXLAN underlay
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true

# ---- SNMP : tuer l'auto-demarre Debian puis relancer avec notre conf ----
killall -9 snmpd 2>/dev/null || true
sleep 1
mkdir -p /etc/snmp /var/lib/snmp /var/agentx
if [ -f /etc/snmp/snmpd.conf ] && command -v snmpd >/dev/null 2>&1; then
  /usr/sbin/snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf
  sleep 1
fi

# Config intégrée : vtysh -b lit /etc/frr/frr.conf (bind-monté) et l'applique à tous les daemons
echo 'service integrated-vtysh-config' > /etc/frr/vtysh.conf

# Option -M snmp : si le module frr-snmp est installe, expose BGP4-MIB via AgentX
SNMP_OPT=""
[ -f /usr/lib/frr/modules/bgpd_snmp.so ] && SNMP_OPT="-M snmp"

# Démarrage des daemons (ordre : mgmtd -> zebra -> reste)
# mgmtd est OBLIGATOIRE en FRR 10.x : gère les IPs des interfaces via zebra
# Sans lui, toutes les "ip address" sont silencieusement ignorées !
/usr/lib/frr/mgmtd   -d -A 127.0.0.1
sleep 1
/usr/lib/frr/zebra   -d -A 127.0.0.1 -s 90000000 $SNMP_OPT
sleep 1
/usr/lib/frr/staticd -d -A 127.0.0.1
grep -q '^ospfd=yes' /etc/frr/daemons 2>/dev/null && /usr/lib/frr/ospfd -d -A 127.0.0.1 $SNMP_OPT
grep -q '^bgpd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bgpd  -d -A 127.0.0.1 $SNMP_OPT
grep -q '^bfdd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bfdd  -d -A 127.0.0.1
sleep 2

# Charger la configuration
vtysh -b 2>/dev/null

# Activer AgentX dans FRR (connexion au snmpd maitre)
[ -n "$SNMP_OPT" ] && vtysh -c 'configure terminal' -c 'agentx' -c 'end' 2>/dev/null || true

# Garder le conteneur vivant
exec tail -f /dev/null

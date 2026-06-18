#!/bin/bash
# ============================================================
# enable-snmp.sh — (Re)active SNMP sur les leafs & spines FRR
# SAE DevCloud 4D01 — Houssam
#
# Depuis le rebuild de l'image, SNMP demarre tout seul au boot des
# conteneurs (docker-start.sh). Ce script sert a forcer un restart
# manuel SANS redeployer, et a (re)activer l'AgentX FRR.
#
# Usage : sudo bash dc1/scripts/enable-snmp.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
PORT=10161

dexec() { docker exec "$1" bash -c "$2"; }

for NODE in "${NODES[@]}"; do
  C="${PREFIX}-${NODE}"
  echo "==> $NODE"

  # 1. (Re)demarrer snmpd sur le port 10161
  #    - on retire agentaddress de la conf bind-montee (peut etre perimee)
  #    - -C : ignorer les confs par defaut ; port force en ligne de commande
  dexec "$C" "
    killall -9 snmpd 2>/dev/null || true; sleep 1
    mkdir -p /var/lib/snmp /var/agentx
    grep -v '^agentaddress' /etc/snmp/snmpd.conf > /run/snmpd.conf 2>/dev/null || cp /etc/snmp/snmpd.conf /run/snmpd.conf
    /usr/sbin/snmpd -Lf /var/log/snmpd.log -C -c /run/snmpd.conf udp:0.0.0.0:${PORT}
  "
  sleep 1
  if dexec "$C" "pgrep -x snmpd >/dev/null"; then
    echo "   snmpd actif sur udp/${PORT}"
  else
    echo "   /!\\ snmpd KO. Log :"
    dexec "$C" "tail -3 /var/log/snmpd.log 2>/dev/null" || true
    continue
  fi

  # 2. (Re)activer l'AgentX FRR (BGP4-MIB) si le module est present
  if dexec "$C" "[ -f /usr/lib/frr/modules/bgpd_snmp.so ]"; then
    dexec "$C" "
      killall -9 zebra bgpd ospfd staticd 2>/dev/null || true; sleep 1
      /usr/lib/frr/zebra   -d -A 127.0.0.1 -s 90000000 -M snmp
      sleep 1
      /usr/lib/frr/staticd -d -A 127.0.0.1
      grep -q '^ospfd=yes' /etc/frr/daemons 2>/dev/null && /usr/lib/frr/ospfd -d -A 127.0.0.1 -M snmp || true
      grep -q '^bgpd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bgpd  -d -A 127.0.0.1 -M snmp || true
      sleep 2
      vtysh -c 'configure terminal' -c 'agentx' -c 'end' 2>/dev/null || true
    " >/dev/null 2>&1 || true
    echo "   AgentX FRR actif (BGP4-MIB)"
  fi
done

echo ""
echo "=== Verification (depuis la VM) ==="
for NODE in "${NODES[@]}"; do
  IP=$(docker inspect -f '{{.NetworkSettings.Networks.clab.IPAddress}}' "${PREFIX}-${NODE}" 2>/dev/null)
  R=$(snmpget -v2c -c public -t 1 -r 1 "${IP}:${PORT}" .1.3.6.1.2.1.1.6.0 2>/dev/null | grep -o 'DC1.*' || echo "PAS DE REPONSE")
  echo "  $NODE ($IP:${PORT}) : $R"
done

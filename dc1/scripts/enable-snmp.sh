#!/bin/bash
# ============================================================
# enable-snmp.sh — Active SNMP sur les leafs & spines FRR
# SAE DevCloud 4D01 — Houssam
#
# A lancer APRES deploy.sh (la topologie doit tourner).
#
# Usage : sudo bash dc1/scripts/enable-snmp.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
SNMPD_CONF="$(cd "$(dirname "$0")/.." && pwd)/services/snmp/snmpd.conf"

if [ ! -f "$SNMPD_CONF" ]; then
  echo "snmpd.conf introuvable : $SNMPD_CONF" >&2
  exit 1
fi

dexec() { docker exec "$1" bash -c "$2"; }

for NODE in "${NODES[@]}"; do
  C="${PREFIX}-${NODE}"
  echo "==> $NODE"

  # 1. Creer le repertoire et copier la conf
  dexec "$C" "mkdir -p /etc/snmp /var/lib/snmp /var/agentx"
  docker cp "$SNMPD_CONF" "${C}:/etc/snmp/snmpd.conf"

  # 2. Arreter un eventuel snmpd restant
  dexec "$C" "pkill -x snmpd 2>/dev/null; sleep 1" || true

  # 3. Demarrer snmpd (erreurs visibles cette fois)
  dexec "$C" "/usr/sbin/snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf" || true
  sleep 1

  if dexec "$C" "pgrep -x snmpd >/dev/null"; then
    echo "   snmpd actif (IF-MIB sur udp/161)"
  else
    echo "   /!\\ snmpd pas demarre. Log :"
    dexec "$C" "cat /var/log/snmpd.log 2>/dev/null | tail -5" || true
  fi

  # 4. FRR AgentX : relancer bgpd/zebra avec -M snmp si le module existe
  MOD=$(dexec "$C" "find /usr/lib -name 'bgpd_snmp.so' 2>/dev/null | head -1" || true)
  if [ -n "$MOD" ]; then
    echo "   module FRR snmp -> relance daemons avec -M snmp + agentx"
    dexec "$C" "
      killall -9 zebra bgpd ospfd staticd 2>/dev/null || true; sleep 1
      /usr/lib/frr/zebra   -d -A 127.0.0.1 -s 90000000 -M snmp 2>&1 | tail -1
      sleep 1
      /usr/lib/frr/staticd -d -A 127.0.0.1 2>&1 | tail -1
      grep -q '^ospfd=yes' /etc/frr/daemons 2>/dev/null && /usr/lib/frr/ospfd -d -A 127.0.0.1 -M snmp || true
      grep -q '^bgpd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bgpd  -d -A 127.0.0.1 -M snmp || true
      sleep 2
      vtysh -c 'configure terminal' -c 'agentx' -c 'end' -c 'write memory' 2>/dev/null || true
    " 2>&1 | grep -v "FD Limit\|stupidly\|attempting direct\|File permissions\|vtysh.conf" || true
    echo "   AgentX FRR actif (BGP4-MIB)"
  else
    echo "   (module FRR snmp absent : IF-MIB OK, BGP4-MIB indispo)"
  fi
done

echo ""
echo "============================================================"
echo " SNMP active. Verifications :"
echo "   snmpwalk -v2c -c public 172.20.20.11 ifDescr"
echo "   snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.15.3"
echo "============================================================"

#!/bin/bash
# ============================================================
# enable-snmp.sh — Active SNMP sur les leafs & spines FRR
# SAE DevCloud 4D01 — Houssam
# Usage : sudo bash dc1/scripts/enable-snmp.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
SNMPD_CONF="$(cd "$(dirname "$0")/.." && pwd)/services/snmp/snmpd.conf"

[ ! -f "$SNMPD_CONF" ] && echo "snmpd.conf introuvable" >&2 && exit 1

dexec() { docker exec "$1" bash -c "$2"; }

for NODE in "${NODES[@]}"; do
  C="${PREFIX}-${NODE}"
  echo "==> $NODE"

  # 1. Repertoire + conf
  dexec "$C" "mkdir -p /etc/snmp /var/lib/snmp /var/agentx"
  docker cp "$SNMPD_CONF" "${C}:/etc/snmp/snmpd.conf"

  # 2. Tuer TOUT ce qui touche au port 161 (snmpd auto-demarre par le paquet Debian)
  dexec "$C" "
    killall -9 snmpd 2>/dev/null || true
    # fuser peut ne pas etre installe, fallback ss
    fuser -k 161/udp 2>/dev/null || true
    sleep 2
  " || true

  # 3. Demarrer snmpd avec notre conf
  dexec "$C" "/usr/sbin/snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf" || true
  sleep 1

  if dexec "$C" "pgrep -x snmpd >/dev/null"; then
    echo "   snmpd actif (IF-MIB sur udp/161)"
  else
    echo "   /!\\ snmpd echec. Log :"
    dexec "$C" "tail -5 /var/log/snmpd.log 2>/dev/null" || true
    echo "   Tentative port 10161..."
    # Fallback : port alternatif
    dexec "$C" "sed -i 's/udp:161/udp:10161/' /etc/snmp/snmpd.conf"
    dexec "$C" "/usr/sbin/snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf" || true
    sleep 1
    if dexec "$C" "pgrep -x snmpd >/dev/null"; then
      echo "   snmpd actif sur port 10161 (penser a adapter prometheus)"
    else
      echo "   /!\\ snmpd ne demarre pas du tout"
      dexec "$C" "tail -5 /var/log/snmpd.log 2>/dev/null" || true
    fi
  fi

  # 4. FRR AgentX
  MOD=$(dexec "$C" "find /usr/lib -name 'bgpd_snmp.so' 2>/dev/null | head -1" || true)
  if [ -n "$MOD" ]; then
    echo "   relance FRR avec -M snmp..."
    dexec "$C" "
      killall -9 zebra bgpd ospfd staticd 2>/dev/null || true; sleep 1
      /usr/lib/frr/zebra   -d -A 127.0.0.1 -s 90000000 -M snmp
      sleep 1
      /usr/lib/frr/staticd -d -A 127.0.0.1
      grep -q '^ospfd=yes' /etc/frr/daemons 2>/dev/null && /usr/lib/frr/ospfd -d -A 127.0.0.1 -M snmp || true
      grep -q '^bgpd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bgpd  -d -A 127.0.0.1 -M snmp || true
      sleep 2
      vtysh -c 'configure terminal' -c 'agentx' -c 'end' 2>/dev/null || true
    " 2>&1 | grep -v "FD Limit\|stupidly\|attempting\|File perm\|vtysh.conf\|Disabling MPLS" || true
    echo "   AgentX FRR actif"
  fi
done

echo ""
echo "=== Verification rapide ==="
for NODE in "${NODES[@]}"; do
  IP=$(docker inspect -f '{{.NetworkSettings.Networks.clab.IPAddress}}' "${PREFIX}-${NODE}" 2>/dev/null || echo "?")
  HAS=$(dexec "${PREFIX}-${NODE}" "pgrep -x snmpd >/dev/null && echo 'snmpd:OK' || echo 'snmpd:KO'" 2>/dev/null)
  echo "  $NODE ($IP) : $HAS"
done

#!/bin/bash
# ============================================================
# enable-snmp.sh — Active SNMP sur les leafs & spines FRR
# SAE DevCloud 4D01 — Houssam
#
# A lancer APRES deploy.sh (la topologie doit tourner).
# Ne touche pas au démarrage FRR de base : on ajoute SNMP par-dessus.
#
# Ce que ça fait sur chaque routeur :
#   1. Installe snmpd s'il manque (apt ou apk selon l'image)
#   2. Copie snmpd.conf (IF-MIB + AgentX maître)
#   3. Démarre snmpd  -> compteurs d'interface visibles en SNMP
#   4. Relance bgpd/zebra/ospfd avec '-M snmp' si le module existe
#      + active 'agentx' dans FRR -> BGP4-MIB / routes visibles en SNMP
#
# Usage : sudo bash dc1/scripts/enable-snmp.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
SNMPD_CONF="$(dirname "$0")/../services/snmp/snmpd.conf"

if [ ! -f "$SNMPD_CONF" ]; then
  echo "snmpd.conf introuvable : $SNMPD_CONF" >&2
  exit 1
fi

dexec() { docker exec "$1" bash -c "$2"; }

for NODE in "${NODES[@]}"; do
  C="${PREFIX}-${NODE}"
  echo "==> $NODE"

  # 1. snmpd présent ?
  if ! dexec "$C" "command -v snmpd >/dev/null 2>&1"; then
    echo "   installation snmpd..."
    if dexec "$C" "command -v apt-get >/dev/null 2>&1"; then
      dexec "$C" "DEBIAN_FRONTEND=noninteractive apt-get update -qq && apt-get install -y -qq snmpd snmp >/dev/null 2>&1" \
        || { echo "   /!\\ apt a échoué (pas d'internet ?) — snmpd doit être dans l'image (voir frr-custom/Dockerfile)"; continue; }
    elif dexec "$C" "command -v apk >/dev/null 2>&1"; then
      dexec "$C" "apk add --no-cache net-snmp net-snmp-tools >/dev/null 2>&1" \
        || { echo "   /!\\ apk a échoué"; continue; }
    fi
  fi

  # 2. conf snmpd
  docker cp "$SNMPD_CONF" "${C}:/etc/snmp/snmpd.conf"

  # 3. (re)démarrer snmpd  (kill propre puis relance en arrière-plan)
  dexec "$C" "pkill -x snmpd 2>/dev/null || true; sleep 1; \
              mkdir -p /var/agentx /var/lib/snmp; \
              /usr/sbin/snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf 2>/dev/null || \
              snmpd -Lf /var/log/snmpd.log -c /etc/snmp/snmpd.conf 2>/dev/null || true"
  sleep 1
  if dexec "$C" "pgrep -x snmpd >/dev/null"; then
    echo "   snmpd actif (IF-MIB dispo sur udp/161)"
  else
    echo "   /!\\ snmpd n'a pas démarré sur $NODE"
  fi

  # 4. FRR AgentX : routes/BGP en SNMP (seulement si le module snmp existe)
  MOD=$(dexec "$C" "find /usr/lib -name 'bgpd_snmp.so' 2>/dev/null | head -1" || true)
  if [ -n "$MOD" ]; then
    echo "   module FRR snmp trouvé -> relance daemons avec -M snmp + agentx"
    dexec "$C" "
      killall -9 zebra bgpd ospfd staticd 2>/dev/null || true; sleep 1
      /usr/lib/frr/zebra   -d -A 127.0.0.1 -s 90000000 -M snmp
      sleep 1
      /usr/lib/frr/staticd -d -A 127.0.0.1
      grep -q '^ospfd=yes' /etc/frr/daemons 2>/dev/null && /usr/lib/frr/ospfd -d -A 127.0.0.1 -M snmp || true
      grep -q '^bgpd=yes'  /etc/frr/daemons 2>/dev/null && /usr/lib/frr/bgpd  -d -A 127.0.0.1 -M snmp || true
      sleep 2
      vtysh -c 'configure terminal' -c 'agentx' -c 'end' -c 'write memory' 2>/dev/null || true
    "
    echo "   BGP4-MIB / OSPF-MIB exposés via AgentX (voir les routes en SNMP)"
  else
    echo "   (module FRR snmp absent dans l'image : IF-MIB OK, mais BGP4-MIB indispo)"
    echo "   -> pour l'activer, rebuild l'image avec frr-custom/Dockerfile (snmpd inclus)"
  fi
done

echo ""
echo "============================================================"
echo " SNMP activé. Vérifications rapides depuis la VM :"
echo "   snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.2.2.1.2   # interfaces leaf1"
echo "   snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.31.1.1.1.6 # octets in (trafic)"
echo "   snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.15.3      # BGP4-MIB (peers/routes)"
echo "============================================================"

#!/bin/bash
# ============================================================
# iperf-test.sh — Génère du trafic entre containers via le fabric VXLAN
# SAE DevCloud 4D01 — Houssam
#
# Sert à : faire monter les compteurs SNMP des leafs (-> Grafana)
#          et mesurer le débit réel à travers l'overlay EVPN/VXLAN.
#
# Par défaut : serveur iperf3 sur web3 (leaf3), client sur web1 (leaf1)
# => le trafic traverse leaf1 -> spine -> leaf3 en VXLAN.
#
# Usage : sudo bash dc1/scripts/iperf-test.sh [duree_sec]
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
SERVER_NODE="web3"      # leaf3
SERVER_IP="172.20.1.12"
CLIENT_NODE="web1"      # leaf1
DUR="${1:-15}"

dexec() { docker exec "$1" sh -c "$2"; }

ensure_iperf() {
  local C="$1"
  if ! dexec "$C" "command -v iperf3 >/dev/null 2>&1"; then
    echo "   installation iperf3 sur $C..."
    dexec "$C" "apk add --no-cache iperf3 >/dev/null 2>&1" \
      || dexec "$C" "apt-get update -qq && apt-get install -y -qq iperf3 >/dev/null 2>&1" \
      || { echo "   /!\\ impossible d'installer iperf3 sur $C"; return 1; }
  fi
}

echo "==> Préparation iperf3"
ensure_iperf "${PREFIX}-${SERVER_NODE}"
ensure_iperf "${PREFIX}-${CLIENT_NODE}"

echo "==> Démarrage serveur iperf3 sur ${SERVER_NODE} (${SERVER_IP})"
dexec "${PREFIX}-${SERVER_NODE}" "pkill iperf3 2>/dev/null || true; sleep 1; iperf3 -s -D"
sleep 2

echo "==> Test connectivité ${CLIENT_NODE} -> ${SERVER_IP}"
dexec "${PREFIX}-${CLIENT_NODE}" "ping -c 2 ${SERVER_IP}" || { echo "ping KO, le fabric ne route pas"; exit 1; }

echo ""
echo "==> Snapshot compteurs SNMP leaf1 AVANT (octets sortie eth3)"
snmpwalk -v2c -c public -t 2 172.20.20.11 .1.3.6.1.2.1.31.1.1.1.10 2>/dev/null | tail -6 || echo "(SNMP pas encore actif — lance enable-snmp.sh)"

echo ""
echo "==> iperf3 ${CLIENT_NODE} -> ${SERVER_NODE} pendant ${DUR}s (TCP)"
dexec "${PREFIX}-${CLIENT_NODE}" "iperf3 -c ${SERVER_IP} -t ${DUR}"

echo ""
echo "==> Test UDP (pour le sampling sFlow / pertes)"
dexec "${PREFIX}-${CLIENT_NODE}" "iperf3 -c ${SERVER_IP} -u -b 100M -t 5"

echo ""
echo "==> Snapshot compteurs SNMP leaf1 APRÈS (octets sortie eth3)"
snmpwalk -v2c -c public -t 2 172.20.20.11 .1.3.6.1.2.1.31.1.1.1.10 2>/dev/null | tail -6 || true

echo ""
echo "==> Nettoyage serveur iperf3"
dexec "${PREFIX}-${SERVER_NODE}" "pkill iperf3 2>/dev/null || true"

echo ""
echo "============================================================"
echo " Trafic généré. Tu dois voir :"
echo "  - le débit TCP/UDP affiché ci-dessus (débit réel de l'overlay)"
echo "  - les compteurs SNMP qui ont augmenté entre AVANT et APRÈS"
echo "  - la courbe de débit dans Grafana (dashboard DC1 - Réseau)"
echo "============================================================"

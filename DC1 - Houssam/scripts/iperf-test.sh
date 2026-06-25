#!/bin/bash
# ============================================================
# iperf-test.sh — Genere du trafic a travers le fabric VXLAN
# SAE DevCloud 4D01 — Houssam
#
# iperf3 tourne sur les leafs FRR (qui l'ont dans l'image).
# On leur donne des IPs temporaires sur br10100 : le trafic
# traverse le VXLAN overlay exactement comme les containers.
#
# leaf1 (172.20.1.251) <-- VXLAN --> leaf3 (172.20.1.253)
#
# Usage : sudo bash dc1/scripts/iperf-test.sh [duree_sec]
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
LEAF_SRV="leaf3"
LEAF_CLI="leaf1"
IP_SRV="172.20.1.250"
IP_CLI="172.20.1.251"
DUR="${1:-15}"

dexec() { docker exec "$1" bash -c "$2"; }

echo "==> Preparation : IPs temporaires sur br10100"
dexec "${PREFIX}-${LEAF_SRV}" "ip addr add ${IP_SRV}/24 dev br10100 2>/dev/null || true"
dexec "${PREFIX}-${LEAF_CLI}" "ip addr add ${IP_CLI}/24 dev br10100 2>/dev/null || true"

echo "==> Connectivite ${LEAF_CLI} (${IP_CLI}) -> ${LEAF_SRV} (${IP_SRV})"
dexec "${PREFIX}-${LEAF_CLI}" "ping -c 2 -W 2 ${IP_SRV}" || { echo "ping KO"; exit 1; }

echo ""
echo "==> Serveur iperf3 sur ${LEAF_SRV}"
dexec "${PREFIX}-${LEAF_SRV}" "pkill iperf3 2>/dev/null || true; sleep 1; iperf3 -s -D -B ${IP_SRV}"
sleep 2

echo "==> iperf3 TCP (${DUR}s) : ${LEAF_CLI} -> ${LEAF_SRV} a travers VXLAN"
dexec "${PREFIX}-${LEAF_CLI}" "iperf3 -c ${IP_SRV} -t ${DUR}"

echo ""
echo "==> iperf3 UDP 100 Mbps (5s)"
dexec "${PREFIX}-${LEAF_CLI}" "iperf3 -c ${IP_SRV} -u -b 100M -t 5"

echo ""
echo "==> Nettoyage"
dexec "${PREFIX}-${LEAF_SRV}" "pkill iperf3 2>/dev/null || true"
dexec "${PREFIX}-${LEAF_SRV}" "ip addr del ${IP_SRV}/24 dev br10100 2>/dev/null || true"
dexec "${PREFIX}-${LEAF_CLI}" "ip addr del ${IP_CLI}/24 dev br10100 2>/dev/null || true"

echo ""
echo "============================================================"
echo " Trafic genere a travers le fabric VXLAN (leaf1 -> leaf3)."
echo " Le debit apparait dans Grafana (dashboard DC1 - Reseau)."
echo "============================================================"

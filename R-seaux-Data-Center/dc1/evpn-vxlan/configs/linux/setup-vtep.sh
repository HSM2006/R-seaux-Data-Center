#!/bin/bash
# ============================================================
# setup-vtep.sh — configure le VTEP (bridge + VXLAN device)
# sur un leaf après le démarrage de Containerlab
#
# Usage : bash setup-vtep.sh <leaf-name>
# Exemple : bash setup-vtep.sh leaf1
#
# Le bridge Linux + le device VXLAN sont la partie "kernel"
# du VTEP. FRR détecte automatiquement le VNI grâce à
# `advertise-all-vni` et l'annonce en BGP EVPN.
# ============================================================

set -e

LEAF=$1
VNI=10100
VXLAN_DEV="vni${VNI}"
BRIDGE_DEV="br${VNI}"

# IP de la loopback du leaf, sert de tunnel source pour VXLAN
case "$LEAF" in
  leaf1) LOCAL_IP="10.0.0.1" ;;
  leaf2) LOCAL_IP="10.0.0.2" ;;
  leaf3) LOCAL_IP="10.0.0.3" ;;
  *) echo "Leaf inconnu : $LEAF" ; exit 1 ;;
esac

CONTAINER="clab-dc1-evpn-${LEAF}"

echo "[+] Setup VTEP sur $LEAF (loopback $LOCAL_IP, VNI $VNI)"

# 1. Créer le bridge L2
docker exec "$CONTAINER" ip link add "$BRIDGE_DEV" type bridge || true
docker exec "$CONTAINER" ip link set "$BRIDGE_DEV" up

# 2. Créer le device VXLAN
#    - id : le VNI
#    - local : IP source des paquets encapsulés (loopback)
#    - dstport 4789 : port UDP standard VXLAN
#    - nolearning : on désactive le learning Ethernet classique,
#      c'est EVPN qui apprend les MAC via BGP
docker exec "$CONTAINER" ip link add "$VXLAN_DEV" type vxlan \
  id "$VNI" \
  local "$LOCAL_IP" \
  dstport 4789 \
  nolearning || true

docker exec "$CONTAINER" ip link set "$VXLAN_DEV" up

# 3. Attacher le VXLAN device au bridge
docker exec "$CONTAINER" ip link set "$VXLAN_DEV" master "$BRIDGE_DEV"

# 4. Attacher l'interface qui va vers les containers (eth10) au bridge
docker exec "$CONTAINER" ip link set eth10 master "$BRIDGE_DEV"
docker exec "$CONTAINER" ip link set eth10 up

echo "[+] VTEP $LEAF prêt. Vérification :"
docker exec "$CONTAINER" bridge link show
docker exec "$CONTAINER" ip -d link show "$VXLAN_DEV" | head -3

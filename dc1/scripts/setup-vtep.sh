#!/bin/bash
# ============================================================
# setup-vtep.sh — Création bridges VXLAN sur les 3 leafs
# Adressage services : 172.20.1.0/24
# VNI : 10100
# Auteur : Houssam
# Usage : bash setup-vtep.sh [leaf1|leaf2|leaf3|all]
# ============================================================

set -e

CONTAINERS=("clab-dc1-evpn-leaf1" "clab-dc1-evpn-leaf2" "clab-dc1-evpn-leaf3")
VNI=10100
BRIDGE="br10100"
VXLAN_IF="vxlan10100"
SERVICE_NET="172.20.1.0/24"

setup_leaf() {
  local CONTAINER=$1
  local VTEP_IP=$2
  local SERVICE_IFACE=$3  # eth3 ou eth4 selon ce qui est libre

  echo "==> Setup VTEP sur $CONTAINER (VTEP IP: $VTEP_IP)"

  docker exec "$CONTAINER" bash -c "
    set -e
    # Activer le forwarding IP
    sysctl -w net.ipv4.ip_forward=1 > /dev/null

    # Persister dans /etc/sysctl.conf
    grep -q 'net.ipv4.ip_forward=1' /etc/sysctl.conf 2>/dev/null || \
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

    # Supprimer le bridge s'il existe déjà (idempotent)
    ip link show $BRIDGE > /dev/null 2>&1 && ip link del $BRIDGE || true
    ip link show $VXLAN_IF > /dev/null 2>&1 && ip link del $VXLAN_IF || true

    # Créer le bridge L2
    ip link add $BRIDGE type bridge
    ip link set $BRIDGE up

    # Créer l'interface VXLAN (VTEP)
    ip link add $VXLAN_IF type vxlan id $VNI local $VTEP_IP dstport 4789 nolearning
    ip link set $VXLAN_IF up

    # Attacher VXLAN au bridge
    ip link set $VXLAN_IF master $BRIDGE

    echo '  Bridge $BRIDGE et VXLAN $VXLAN_IF créés'
  "

  echo "  OK $CONTAINER"
}

setup_host_veth() {
  echo "==> Setup veth host -> br10100 sur leaf1"
  LEAF1="clab-dc1-evpn-leaf1"
  HOST_IP="172.20.1.254"

  # Veth pair : veth-host (host) <-> veth-leaf (dans leaf1)
  ip link show veth-host > /dev/null 2>&1 && ip link del veth-host || true

  ip link add veth-host type veth peer name veth-leaf

  # Passer veth-leaf dans le namespace du container leaf1
  PID=$(docker inspect -f '{{.State.Pid}}' "$LEAF1")
  ip link set veth-leaf netns "$PID"

  # Config côté leaf1
  docker exec "$LEAF1" bash -c "
    ip link set veth-leaf up
    ip link set veth-leaf master $BRIDGE
  "

  # Config côté host
  ip link set veth-host up
  ip addr add ${HOST_IP}/24 dev veth-host || true

  echo "  Host connecté au fabric VXLAN via veth-host (IP: $HOST_IP)"
}

# iptables pour permettre le forwarding
setup_iptables() {
  echo "==> Configuration iptables"
  iptables -P FORWARD ACCEPT
  iptables -I DOCKER-USER -j ACCEPT 2>/dev/null || true
  echo "  iptables OK"
}

# Main
case "${1:-all}" in
  leaf1)
    setup_leaf "clab-dc1-evpn-leaf1" "172.16.255.11"
    ;;
  leaf2)
    setup_leaf "clab-dc1-evpn-leaf2" "172.16.255.12"
    ;;
  leaf3)
    setup_leaf "clab-dc1-evpn-leaf3" "172.16.255.13"
    ;;
  all)
    setup_iptables
    setup_leaf "clab-dc1-evpn-leaf1" "172.16.255.11"
    setup_leaf "clab-dc1-evpn-leaf2" "172.16.255.12"
    setup_leaf "clab-dc1-evpn-leaf3" "172.16.255.13"

    # Attacher eth3/eth4 (services) au bridge sur chaque leaf
    for LEAF in "clab-dc1-evpn-leaf1" "clab-dc1-evpn-leaf2" "clab-dc1-evpn-leaf3"; do
      docker exec "$LEAF" bash -c "
        for IFACE in eth3 eth4; do
          ip link show \$IFACE > /dev/null 2>&1 && {
            ip link set \$IFACE up
            ip link set \$IFACE master br10100
            echo '  \$IFACE attaché à br10100 sur \$(hostname)'
          } || true
        done
      "
    done

    setup_host_veth
    echo ""
    echo "=== VTEP setup terminé ==="
    echo "Services subnet : $SERVICE_NET"
    echo "Gateway host    : 172.20.1.254"
    echo "VNI             : $VNI"
    ;;
  *)
    echo "Usage: $0 [leaf1|leaf2|leaf3|all]"
    exit 1
    ;;
esac

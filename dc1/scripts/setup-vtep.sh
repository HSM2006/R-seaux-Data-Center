#!/bin/bash
# ============================================================
# setup-vtep.sh — Bridges VXLAN sur les leafs + transport sur les spines
# SAE DevCloud 4D01 — Houssam
# VNI 10100 / services 172.20.1.0/24 / gateway host 172.20.1.254
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
VNI=10100
BRIDGE="br10100"
VXLAN_IF="vxlan10100"

# loopback (= local VTEP IP) de chaque leaf
declare -A VTEP_IP=(
  [leaf1]="172.16.255.11"
  [leaf2]="172.16.255.12"
  [leaf3]="172.16.255.13"
)

dexec() { docker exec "$1" bash -c "$2"; }

# ---- ip_forward partout (les SPINES routent le transport VXLAN underlay) ----
echo "==> ip_forward sur tous les noeuds FRR"
for NODE in spine1 spine2 leaf1 leaf2 leaf3; do
  dexec "${PREFIX}-${NODE}" "sysctl -w net.ipv4.ip_forward=1 >/dev/null"
done

# ---- iptables host : autoriser le forward ----
echo "==> iptables FORWARD ACCEPT (host)"
iptables -P FORWARD ACCEPT 2>/dev/null || true
iptables -I DOCKER-USER -j ACCEPT 2>/dev/null || true

# ---- Bridge + VXLAN sur chaque leaf ----
for LEAF in leaf1 leaf2 leaf3; do
  C="${PREFIX}-${LEAF}"
  IP="${VTEP_IP[$LEAF]}"
  echo "==> VTEP $LEAF (local $IP)"

  # idempotent
  dexec "$C" "ip link del $VXLAN_IF 2>/dev/null || true; ip link del $BRIDGE 2>/dev/null || true"

  # bridge L2
  dexec "$C" "ip link add $BRIDGE type bridge; ip link set $BRIDGE up"

  # interface VXLAN (VTEP)
  dexec "$C" "ip link add $VXLAN_IF type vxlan id $VNI local $IP dstport 4789 nolearning"
  dexec "$C" "ip link set $VXLAN_IF master $BRIDGE; ip link set $VXLAN_IF up"

  # attacher les ports services eth3 + eth4 au bridge
  for IFACE in eth3 eth4; do
    if dexec "$C" "ip link show $IFACE >/dev/null 2>&1"; then
      dexec "$C" "ip link set $IFACE up; ip link set $IFACE master $BRIDGE"
      echo "   $IFACE -> $BRIDGE"
    fi
  done
done

# ---- IP sur leaf1 br10100 pour injection BGP de 172.20.1.0/24 ----
# FRR sur leaf1 a `network 172.20.1.0/24` — il faut une route connected
# dans le RIB pour que le network statement soit actif.
echo "==> IP 172.20.1.253/24 sur leaf1 br10100 (pour annonce BGP)"
dexec "${PREFIX}-leaf1" "ip addr add 172.20.1.253/24 dev $BRIDGE 2>/dev/null || true"

# ---- Connexion du host VM au fabric (gateway services) ----
# Le veth-host reste pour la default route des containers (accès internet).
# Le trafic ENTRANT passe maintenant par les spines (macvlan → eBGP).
echo "==> veth host -> $BRIDGE sur leaf1 (gateway 172.20.1.254)"
L1="${PREFIX}-leaf1"
ip link del veth-host 2>/dev/null || true
ip link add veth-host type veth peer name veth-leaf
PID=$(docker inspect -f '{{.State.Pid}}' "$L1")
ip link set veth-leaf netns "$PID"
docker exec "$L1" ip link set veth-leaf up
docker exec "$L1" ip link set veth-leaf master "$BRIDGE"
ip link set veth-host up
ip addr add 172.20.1.254/24 dev veth-host 2>/dev/null || true

echo ""
echo "=== VTEP setup terminé : VNI $VNI, services 172.20.1.0/24, gw 172.20.1.254 ==="

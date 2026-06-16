#!/bin/bash
# check-bgp.sh — Vérification BGP + EVPN + connectivité
# Auteur : Houssam

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")

echo "=== BGP Summary ==="
for NODE in "${NODES[@]}"; do
  echo "--- $NODE ---"
  docker exec "${PREFIX}-${NODE}" vtysh -c "show bgp summary" 2>/dev/null | \
    grep -E "Neighbor|Estab|Active|65" | head -10
done

echo ""
echo "=== EVPN VNI ==="
for LEAF in leaf1 leaf2 leaf3; do
  echo "--- $LEAF ---"
  docker exec "${PREFIX}-${LEAF}" vtysh -c "show evpn vni" 2>/dev/null
done

echo ""
echo "=== EVPN Routes Type-3 ==="
docker exec "${PREFIX}-leaf1" vtysh -c "show bgp l2vpn evpn" 2>/dev/null | grep -E "Route|Type-3|IMET" | head -20

echo ""
echo "=== Ping inter-leaf ==="
echo "web1 (172.20.1.10) -> web2 (172.20.1.11):"
docker exec "${PREFIX}-web1" ping -c 3 172.20.1.11 2>/dev/null && echo "OK" || echo "FAIL"
echo "web1 (172.20.1.10) -> dns1 (172.20.1.20):"
docker exec "${PREFIX}-web1" ping -c 3 172.20.1.20 2>/dev/null && echo "OK" || echo "FAIL"

echo ""
echo "=== Catalyst route check ==="
echo "Attente que le Catalyst (10.202.0.12) annonce 172.20.1.0/24..."

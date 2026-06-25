#!/bin/bash
# check-bgp.sh — Verification BGP/EVPN/connectivite DC2
PREFIX="clab-dc2-evpn"

echo "=== BGP underlay (ipv4) sur les leafs ==="
for L in leaf1 leaf2 leaf3; do
  echo "--- $L ---"
  docker exec ${PREFIX}-$L Cli -c "show bgp ipv4 unicast summary" 2>/dev/null | grep -E "Neighbor|Estab|65000|65002"
done

echo ""
echo "=== BGP eBGP sur les spines (vers VM AS 65002) ==="
for S in spine1 spine2; do
  echo "--- $S ---"
  docker exec ${PREFIX}-$S Cli -c "show bgp ipv4 unicast summary" 2>/dev/null | grep -E "Neighbor|Estab|65000|65002"
done

echo ""
echo "=== BGP cote VM Debian ==="
vtysh -c "show ip bgp summary" 2>&1 | head -15

echo ""
echo "=== VXLAN VTEP (avec workaround statique) ==="
for L in leaf1 leaf2 leaf3; do
  echo "--- $L ---"
  docker exec ${PREFIX}-$L Cli -c "show vxlan vtep" 2>/dev/null
done

echo ""
echo "=== Connectivite ==="
ping -c 2 -W 2 172.20.2.10 >/dev/null 2>&1 && echo "[OK] VM -> web1"     || echo "[KO] VM -> web1"
ping -c 2 -W 2 172.20.2.11 >/dev/null 2>&1 && echo "[OK] VM -> web2 VXLAN" || echo "[KO] VM -> web2"
docker exec ${PREFIX}-web1 ping -c 2 -W 2 10.202.1.12 >/dev/null 2>&1 && echo "[OK] web1 -> Catalyst (10.202.1.12)" || echo "[KO] web1 -> Catalyst"

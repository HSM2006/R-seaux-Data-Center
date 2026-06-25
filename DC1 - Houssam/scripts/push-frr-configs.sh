#!/bin/bash
# push-frr-configs.sh — Injecter les configs FRR dans les containers
# après clab deploy (car les mounts ne se font pas toujours au runtime)
# Auteur : Houssam

set -e

TOPO_DIR="$(dirname "$0")/../containerlab"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
PREFIX="clab-dc1-evpn"
MODE="${1:-bgp}"  # bgp ou ospf

echo "==> Push configs FRR (underlay: $MODE)"

for NODE in "${NODES[@]}"; do
  CONTAINER="${PREFIX}-${NODE}"
  CONFIG_FILE="${TOPO_DIR}/frr/${MODE}/${NODE}.conf"

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "  WARN: $CONFIG_FILE introuvable, skip"
    continue
  fi

  echo "  -> $CONTAINER"
  docker cp "$CONFIG_FILE" "${CONTAINER}:/etc/frr/frr.conf"
  docker cp "${TOPO_DIR}/frr/daemons" "${CONTAINER}:/etc/frr/daemons"

  # Restart FRR proprement (sans frrinit.sh qui bloque sur watchfrr)
  docker exec "$CONTAINER" bash -c "
    killall -9 zebra bgpd ospfd staticd bfdd 2>/dev/null || true
    sleep 1
    /usr/lib/frr/zebra -d -A 127.0.0.1 -s 90000000
    sleep 1
    /usr/lib/frr/bgpd -d -A 127.0.0.1
    /usr/lib/frr/staticd -d -A 127.0.0.1
    [ '$MODE' = 'ospf' ] && /usr/lib/frr/ospfd -d -A 127.0.0.1 || true
    echo '  FRR redémarré sur $(hostname)'
  "
done

echo ""
echo "=== Push FRR terminé ==="
echo "Vérification BGP dans 10s..."
sleep 10
for NODE in "${NODES[@]}"; do
  CONTAINER="${PREFIX}-${NODE}"
  echo "--- $NODE ---"
  docker exec "$CONTAINER" vtysh -c "show bgp summary" 2>/dev/null | grep -E "Neighbor|Established|Active" || true
done

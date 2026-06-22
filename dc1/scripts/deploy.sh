#!/bin/bash
# deploy.sh — Déploiement complet DC1 (SAE DevCloud 4D01, Houssam)
# Usage : sudo bash deploy.sh [--ospf]
set -e
cd "$(dirname "$0")/.."

MODE="bgp"
[ "$1" = "--ospf" ] && MODE="ospf"

echo "============================================"
echo "  SAE DevCloud 4D01 — Déploiement DC1"
echo "  Underlay : $MODE | Services : 172.20.1.0/24"
echo "============================================"

# 1. (Re)build images
echo "[1/7] Build image FRR custom..."
docker build -t frrouting/frr:latest frr-custom/

echo "[2/7] Build image DNS custom (Unbound)..."
docker build -t dc1-dns:latest dns-custom/

# 3. Nettoyage ancienne topo
echo "[3/7] Nettoyage ancienne topologie..."
cd containerlab
sudo clab destroy -t topology.clab.yml --cleanup 2>/dev/null || true
sleep 2

# 4. Choix underlay
echo "[4/7] Underlay = $MODE"
if [ "$MODE" = "ospf" ]; then
  cp -f frr/ospf/*.conf frr/bgp/
  echo "  Configs OSPF copiées dans frr/bgp/ (bind-mount)"
else
  git -C .. checkout -- containerlab/frr/bgp/ 2>/dev/null || true
fi

# 5. Déploiement Containerlab
echo "[5/7] Déploiement Containerlab..."
sudo clab deploy -t topology.clab.yml
sleep 8
echo "  Vérification FRR..."
for NODE in leaf1 leaf2 leaf3 spine1 spine2; do
  N=$(docker exec "clab-dc1-evpn-${NODE}" sh -c "pgrep -c bgpd" 2>/dev/null || echo 0)
  echo "  ${NODE}: bgpd actif=${N}"
done

# 6. Setup VXLAN (bridges + VTEP + veth-host)
echo "[6/7] Setup VXLAN..."
cd ..
bash scripts/setup-vtep.sh
sleep 3

# 7. Setup border links (macvlan spine1→Catalyst, spine2→Mikrotik)
echo "[7/7] Setup border links (macvlan → eBGP)..."
bash scripts/setup-border-links.sh
sleep 5

echo ""
echo "============================================"
echo "  Déploiement terminé !"
echo "============================================"
bash scripts/check-bgp.sh

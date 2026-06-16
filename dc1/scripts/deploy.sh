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

# 1. (Re)build image FRR — l'entrypoint démarre FRR proprement + ip_forward
echo "[1/5] Build image FRR custom..."
docker build -t frrouting/frr:latest frr-custom/

# 2. Nettoyage ancienne topo
echo "[2/5] Nettoyage ancienne topologie..."
cd containerlab
sudo clab destroy -t topology.clab.yml --cleanup 2>/dev/null || true
sleep 2

# 3. Choix underlay : la topo bind-monte frr/bgp/*.conf. Pour OSPF on copie par-dessus.
echo "[3/5] Underlay = $MODE"
if [ "$MODE" = "ospf" ]; then
  cp -f frr/ospf/*.conf frr/bgp/
  echo "  Configs OSPF copiées dans frr/bgp/ (bind-mount)"
else
  git -C .. checkout -- containerlab/frr/bgp/ 2>/dev/null || true
fi

# 4. Déploiement (FRR démarre via l'entrypoint de l'image)
echo "[4/5] Déploiement Containerlab..."
sudo clab deploy -t topology.clab.yml
sleep 8
echo "  Vérification FRR..."
for NODE in leaf1 leaf2 leaf3 spine1 spine2; do
  N=$(docker exec "clab-dc1-evpn-${NODE}" sh -c "pgrep -c bgpd" 2>/dev/null || echo 0)
  echo "  ${NODE}: bgpd actif=${N}"
done

# 5. Bridges VXLAN + transport
echo "[5/5] Setup VXLAN..."
cd ..
bash scripts/setup-vtep.sh
sleep 5

echo ""
echo "============================================"
echo "  Déploiement terminé !"
echo "============================================"
bash scripts/check-bgp.sh

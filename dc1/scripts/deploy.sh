#!/bin/bash
# deploy.sh — Déploiement complet DC1
# Auteur : Houssam
# Usage : sudo bash deploy.sh [--ospf]

set -e
cd "$(dirname "$0")/.."

MODE="bgp"
[ "$1" = "--ospf" ] && MODE="ospf"

echo "============================================"
echo "  SAE DevCloud 4D01 — Déploiement DC1"
echo "  Underlay : $MODE"
echo "  Services : 172.20.1.0/24"
echo "============================================"

# 1. Build image FRR custom si nécessaire
if ! docker image inspect frrouting/frr:latest | grep -q frr-custom 2>/dev/null; then
  echo "[1/5] Build image FRR custom..."
  docker build -t frrouting/frr:latest frr-custom/ || true
else
  echo "[1/5] Image FRR custom déjà présente"
fi

# 2. Détruire ancienne topo
echo "[2/5] Nettoyage ancienne topologie..."
cd containerlab
sudo clab destroy -t topology.clab.yml --cleanup 2>/dev/null || true
sleep 2

# 3. Copier les bonnes configs selon le mode (bgp ou ospf)
echo "[3/5] Préparation configs underlay: $MODE..."
# La topo bind-mount frr/bgp/*.conf — si on veut ospf, on copie par dessus
if [ "$MODE" = "ospf" ]; then
  cp -f frr/ospf/*.conf frr/bgp/
  echo "  Configs OSPF copiées dans frr/bgp/"
fi

# 4. Déployer la topologie (configs injectées via bind mounts)
echo "[4/5] Déploiement Containerlab..."
sudo clab deploy -t topology.clab.yml
sleep 5

# FRR démarre automatiquement via l'entrypoint de l'image
# Vérification que les daemons tournent
echo "  Vérification FRR..."
for NODE in leaf1 leaf2 leaf3 spine1 spine2; do
  PIDS=$(docker exec "clab-dc1-evpn-${NODE}" pgrep -c "bgpd\|zebra\|ospfd" 2>/dev/null || echo "0")
  echo "  ${NODE}: ${PIDS} daemons FRR actifs"
done

# 5. Setup bridges VXLAN
echo "[5/5] Setup bridges VXLAN..."
cd ..
bash scripts/setup-vtep.sh all
sleep 5

echo ""
echo "============================================"
echo "  Déploiement terminé !"
echo "============================================"
bash scripts/check-bgp.sh

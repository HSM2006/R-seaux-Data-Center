#!/bin/bash
# deploy.sh — Déploiement complet DC1
# Auteur : Houssam
# Usage : sudo bash deploy.sh [--ospf]

set -e
cd "$(dirname "$0")/.."

MODE="bgp"
[ "$1" = "--ospf" ] && MODE="ospf"
CLAB_DIR="containerlab"

echo "============================================"
echo "  SAE DevCloud 4D01 — Déploiement DC1"
echo "  Underlay : $MODE"
echo "  Services : 172.20.1.0/24"
echo "============================================"

# 1. Construire l'image FRR custom si nécessaire
if ! docker image inspect frrouting/frr:custom > /dev/null 2>&1; then
  echo "[1/6] Build image FRR custom..."
  docker build -t frrouting/frr:latest frr-custom/
else
  echo "[1/6] Image FRR custom déjà présente, skip"
fi

# 2. Détruire ancienne topo si elle existe
echo "[2/6] Nettoyage ancienne topologie..."
cd "$CLAB_DIR"
sudo clab destroy -t topology.clab.yml --cleanup 2>/dev/null || true
sleep 2

# 3. Déployer la topologie
echo "[3/6] Déploiement Containerlab..."
sudo clab deploy -t topology.clab.yml
sleep 5

# 4. Push configs FRR
echo "[4/6] Injection configs FRR (underlay: $MODE)..."
cd ..
bash scripts/push-frr-configs.sh "$MODE"
sleep 10

# 5. Setup bridges VXLAN
echo "[5/6] Setup bridges VXLAN..."
bash scripts/setup-vtep.sh all
sleep 5

# 6. Démarrer les services host
echo "[6/6] Démarrage services host (Nautobot, Oxidized, Observabilité)..."
cd services
docker compose -f docker-compose.yml up -d 2>/dev/null || docker-compose -f docker-compose.yml up -d
sleep 5

echo ""
echo "============================================"
echo "  Déploiement terminé !"
echo "  Lancez check-bgp.sh pour vérifier"
echo "============================================"
bash ../scripts/check-bgp.sh

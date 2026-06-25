#!/bin/bash
# ============================================================
# enable-frr-exporter.sh — (OPTIONNEL) métriques FRR natives
# SAE DevCloud 4D01 — Houssam
#
# Déploie frr_exporter (port 9342) dans chaque routeur FRR.
# Complète le SNMP : expose les métriques BGP/EVPN telles que FRR
# les voit (peers, routes, états VNI). Prometheus a déjà le job
# 'frr-exporter' prêt.
#
# Nécessite Internet sur la VM (télécharge le binaire depuis GitHub).
# Le SNMP suffit pour l'éval : ce script est un bonus.
#
# Usage : sudo bash 'DC1 - Houssam/scripts/enable-frr-exporter.sh' [version]
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
NODES=("leaf1" "leaf2" "leaf3" "spine1" "spine2")
VER="${1:-1.4.0}"
ARCH="linux-amd64"
URL="https://github.com/tynany/frr_exporter/releases/download/v${VER}/frr_exporter-${VER}.${ARCH}"

echo "==> Téléchargement frr_exporter v${VER} sur la VM"
TMP="/tmp/frr_exporter"
curl -fsSL -o "$TMP" "$URL" || {
  echo "Échec du téléchargement. Vérifie la version sur :"
  echo "  https://github.com/tynany/frr_exporter/releases"
  exit 1
}
chmod +x "$TMP"

for NODE in "${NODES[@]}"; do
  C="${PREFIX}-${NODE}"
  echo "==> $NODE : copie + lancement frr_exporter"
  docker cp "$TMP" "${C}:/usr/local/bin/frr_exporter"
  docker exec "$C" sh -c "
    pkill frr_exporter 2>/dev/null || true; sleep 1
    nohup /usr/local/bin/frr_exporter \
      --frr.socket.dir-path=/var/run/frr \
      --web.listen-address=:9342 >/var/log/frr_exporter.log 2>&1 &
  "
  sleep 1
  docker exec "$C" sh -c "pgrep frr_exporter >/dev/null && echo '   OK (9342)' || echo '   /!\\ pas démarré'"
done

echo ""
echo "Vérif : curl http://172.20.20.11:9342/metrics | grep frr_bgp"

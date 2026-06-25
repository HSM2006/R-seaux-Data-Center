#!/bin/bash
# ============================================================
# webload-test.sh — Test de charge applicatif (HTTP) sur les
# services web DC1, a travers HAProxy et le fabric VXLAN
# SAE DevCloud 4D01 — Houssam
#
# Contrairement a iperf-test.sh (debit brut L3/L4), ce script
# teste la couche applicative : requetes HTTP concurrentes contre
# le VIP HAProxy (172.20.1.40), qui repartit vers web1/web2/web3
# sur les trois leafs. Sert a montrer que le fabric tient la
# charge cote service, pas seulement cote reseau.
#
# Necessite "ab" (apache2-utils) sur la VM hote :
#   sudo apt install -y apache2-utils
#
# Usage :
#   sudo bash dc1/scripts/webload-test.sh [requetes] [concurrence] [cible]
#   sudo bash dc1/scripts/webload-test.sh 2000 50
#   sudo bash dc1/scripts/webload-test.sh 2000 50 172.20.2.10   # vers DC2 (Arista), test multi-vendor
# ============================================================
set -e

REQS="${1:-2000}"
CONCURRENCY="${2:-50}"
TARGET="${3:-172.20.1.40}"

if ! command -v ab >/dev/null 2>&1; then
  echo "[!] 'ab' n'est pas installe. Lance : sudo apt install -y apache2-utils"
  exit 1
fi

echo "============================================================"
echo " Test de charge HTTP : ${REQS} requetes, concurrence ${CONCURRENCY}"
echo " Cible : http://${TARGET}/"
echo "============================================================"

echo ""
echo "==> Verification rapide (la cible doit repondre 200)"
curl -s -o /dev/null -w "HTTP %{http_code} en %{time_total}s\n" "http://${TARGET}/" || {
  echo "[!] Cible injoignable, abandon."
  exit 1
}

echo ""
echo "==> Lancement du test de charge (ab)"
ab -n "${REQS}" -c "${CONCURRENCY}" "http://${TARGET}/" | tee /tmp/webload-result.txt

echo ""
echo "==> Repartition observee cote HAProxy (si cible = VIP HAProxy)"
echo "    Page stats : http://${TARGET%:*}:8404/stats"

echo ""
echo "==> Resume"
grep -E "Requests per second|Time per request|Failed requests|Transfer rate" /tmp/webload-result.txt

echo ""
echo "============================================================"
echo " Pendant le test, le pic de requetes/sec doit apparaitre"
echo " dans Grafana (debit par interface) en plus du resultat ab."
echo " Pour tester le multi-vendor, relancer en pointant vers le"
echo " service web de l'autre datacenter (3e argument)."
echo "============================================================"

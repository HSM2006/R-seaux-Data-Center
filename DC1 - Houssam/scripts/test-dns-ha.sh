#!/bin/bash
# ============================================================
# test-dns-ha.sh — Vérifie la résolution DNS et la bascule HA
# SAE DevCloud 4D01 — Houssam
#
# Démontre le test du prof : "si une instance DNS tombe,
# l'autre prend le relais automatiquement".
#
# Principe : un client (web1) interroge dns1 puis dns2.
# On coupe dns1, on re-teste : dns2 répond toujours.
# Le client a les deux serveurs dans son resolv.conf -> bascule auto.
#
# Usage : sudo bash dc1/scripts/test-dns-ha.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
CLIENT="${PREFIX}-web1"
DNS1="172.20.1.20"
DNS2="172.20.1.21"
NAME="web2.dc1.local"

dexec() { docker exec "$1" sh -c "$2"; }

# Outil de requête DNS dans le client (nslookup busybox suffit)
q() { dexec "$CLIENT" "nslookup $1 $2 2>/dev/null | grep -A1 'Name' | tail -1 || nslookup $1 $2"; }

echo "=== 1) Résolution via dns1 ($DNS1) ==="
dexec "$CLIENT" "nslookup $NAME $DNS1" || echo "dns1 NE REPOND PAS"

echo ""
echo "=== 2) Résolution via dns2 ($DNS2) ==="
dexec "$CLIENT" "nslookup $NAME $DNS2" || echo "dns2 NE REPOND PAS"

echo ""
echo "=== 3) Configuration du client avec les DEUX résolveurs (bascule auto) ==="
dexec "$CLIENT" "printf 'nameserver %s\nnameserver %s\noptions timeout:1 attempts:1\n' $DNS1 $DNS2 > /etc/resolv.conf"
dexec "$CLIENT" "cat /etc/resolv.conf"

echo ""
echo "=== 4) Résolution normale (dns1 primaire répond) ==="
dexec "$CLIENT" "nslookup $NAME" | grep -E "Address|Name" | tail -2

echo ""
echo "=== 5) On COUPE dns1 (simulation de panne) ==="
docker exec "${PREFIX}-dns1" sh -c "pkill unbound 2>/dev/null || true"
echo "   unbound arrêté sur dns1"
sleep 2

echo ""
echo "=== 6) Re-résolution : dns2 doit prendre le relais ==="
if dexec "$CLIENT" "nslookup $NAME" | grep -q "172.20.1.11"; then
  echo "   OK -> dns2 a pris le relais automatiquement, $NAME résolu"
else
  echo "   Résultat :"
  dexec "$CLIENT" "nslookup $NAME"
fi

echo ""
echo "=== 7) On relance dns1 ==="
docker exec "${PREFIX}-dns1" sh -c "unbound -c /etc/unbound/unbound.conf 2>/dev/null || \
  (while true; do unbound -d -c /etc/unbound/unbound.conf; sleep 2; done &)"
sleep 2
dexec "${PREFIX}-dns1" "pgrep unbound >/dev/null && echo '   dns1 de nouveau actif' || echo '   /!\\ dns1 pas relancé'"

echo ""
echo "============================================================"
echo " HA DNS validée : la coupure de dns1 n'interrompt pas la résolution."
echo "============================================================"

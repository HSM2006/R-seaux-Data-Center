#!/bin/bash
# install-frr.sh — Installe et configure FRR sur la VM Debian (AS 65002)
# A executer une seule fois. Idempotent.
set -e

echo "[install-frr] Installation FRR (si pas deja fait)..."
if ! command -v vtysh &>/dev/null; then
  apt-get update
  apt-get install -y frr frr-pythontools
fi

echo "[install-frr] Configuration des daemons..."
cp "$(dirname "$0")/../host-frr/daemons" /etc/frr/daemons

echo "[install-frr] Configuration FRR (frr.conf)..."
cp "$(dirname "$0")/../host-frr/frr.conf" /etc/frr/frr.conf
chown frr:frr /etc/frr/frr.conf /etc/frr/daemons
chmod 640 /etc/frr/frr.conf
chmod 640 /etc/frr/daemons

echo "[install-frr] Activation forwarding noyau..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-dc2-forward.conf

echo "[install-frr] Demarrage FRR..."
systemctl enable frr
systemctl restart frr

sleep 3
echo ""
echo "[install-frr] Termine. Verification :"
vtysh -c "show ip bgp summary" 2>/dev/null || echo "(BGP pas encore up - normal si les spines ne sont pas demarres)"

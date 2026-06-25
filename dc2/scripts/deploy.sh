#!/bin/bash
# deploy.sh — Deploiement complet DC2 v4 (cEOS + FRR sur la VM)
# Usage : sudo bash deploy.sh
set -e
cd "$(dirname "$0")/.."

echo "============================================"
echo "  DC2 v4 — eBGP VM <-> spines (AS 65002)"
echo "============================================"

# 1. iptables FORWARD + DOCKER-USER
echo "[1/5] Fix iptables FORWARD..."
iptables -P FORWARD ACCEPT
iptables -F DOCKER-USER 2>/dev/null || true
iptables -I DOCKER-USER -j ACCEPT

# 2. Forwarding noyau (avec rp_filter desactive pour les liens spines)
echo "[2/5] Activation forwarding noyau + rp_filter..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 >/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 >/dev/null
# ens18 reste a 0 pour autoriser le routage asymetrique
sysctl -w net.ipv4.conf.ens18.rp_filter=0 >/dev/null

# 3. Verifier que FRR est installe et configure (sinon le faire)
if [ ! -f /etc/frr/frr.conf ] || ! grep -q "bgp 65002" /etc/frr/frr.conf 2>/dev/null; then
  echo "[3/5] FRR pas encore installe/configure, lancement install-frr.sh..."
  bash "$(dirname "$0")/install-frr.sh"
else
  echo "[3/5] FRR deja configure (saut)"
fi

# 4. Deploy containerlab
echo "[4/5] Deploiement Containerlab..."
cd containerlab
sudo clab destroy -t topology.clab.yml --cleanup 2>/dev/null || true
sleep 2
sudo clab deploy -t topology.clab.yml
sleep 30

# 5. Configurer les IP des veth-spines et redemarrer FRR
echo "[5/5] Config veth-spines + redemarrage FRR..."
cd ..
bash scripts/setup-host-links.sh
systemctl restart frr
sleep 15

echo ""
echo "============================================"
echo "  Verifications"
echo "============================================"

echo ""
echo "--- BGP underlay sur leaf1 ---"
docker exec clab-dc2-evpn-leaf1 Cli -c "show bgp ipv4 unicast summary" 2>&1 | head -10

echo ""
echo "--- BGP eBGP sur la VM (vers spine1 et spine2) ---"
vtysh -c "show ip bgp summary" 2>&1 | head -15

echo ""
echo "--- Routes BGP apprises par la VM ---"
vtysh -c "show ip bgp" 2>&1 | head -15

echo ""
echo "--- Routes installees dans la table VM ---"
ip route show | grep -E "172.20.2|172.16"

echo ""
echo "--- Tests ping ---"
ping -c 2 -W 2 172.16.2.1 >/dev/null 2>&1 && echo "[OK] VM -> spine1 (172.16.2.1)" || echo "[KO] VM -> spine1"
ping -c 2 -W 2 172.16.2.5 >/dev/null 2>&1 && echo "[OK] VM -> spine2 (172.16.2.5)" || echo "[KO] VM -> spine2"
ping -c 2 -W 2 172.20.2.254 >/dev/null 2>&1 && echo "[OK] VM -> gateway DC2 (172.20.2.254)" || echo "[KO] VM -> gateway"
ping -c 2 -W 2 172.20.2.10 >/dev/null 2>&1 && echo "[OK] VM -> web1 (172.20.2.10)"     || echo "[KO] VM -> web1"
ping -c 2 -W 2 172.20.2.11 >/dev/null 2>&1 && echo "[OK] VM -> web2 (172.20.2.11)"     || echo "[KO] VM -> web2"

echo ""
echo "Deploiement termine !"

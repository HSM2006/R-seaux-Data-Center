#!/bin/bash
# setup-host-links.sh — Configure les IP sur les veth host cree par containerlab
# A executer apres chaque "clab deploy"
set -e

echo "[setup-host-links] Configuration veth-spine1 (172.16.2.2/30)..."
ip addr add 172.16.2.2/30 dev veth-spine1 2>/dev/null || true
ip link set veth-spine1 up

echo "[setup-host-links] Configuration veth-spine2 (172.16.2.6/30)..."
ip addr add 172.16.2.6/30 dev veth-spine2 2>/dev/null || true
ip link set veth-spine2 up

echo "[setup-host-links] Resume :"
ip -br addr show | grep -E "veth-spine|ens18"

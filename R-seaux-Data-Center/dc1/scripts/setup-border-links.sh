#!/bin/bash
# ============================================================
# setup-border-links.sh — macvlan pour connecter spines aux border routers
# SAE DevCloud 4D01 — Houssam
#
# Crée des interfaces macvlan sur ens18 et les déplace dans
# le namespace des spines. Permet les sessions eBGP :
#   spine1 (10.202.1.201) <-> Catalyst (10.202.1.12)  AS 65000 <-> AS 65001
#   spine2 (10.202.1.202) <-> Mikrotik (10.202.1.13)  AS 65000 <-> AS 65001
#
# Usage : sudo bash setup-border-links.sh
# Idempotent : peut être relancé sans casser.
# Ne survit PAS au reboot — appelé depuis deploy.sh
# ============================================================
set -e

PREFIX="clab-dc1-evpn"
HOST_IF="ens18"

# IPs dans le réseau de la salle (10.202.0.0/16)
# VÉRIFIER qu'elles sont libres : ping -c1 10.202.1.201 && ping -c1 10.202.1.202
SPINE1_EXT_IP="10.202.1.201/16"
SPINE2_EXT_IP="10.202.1.202/16"

setup_macvlan() {
    local CONTAINER="$1"
    local MACVLAN_NAME="$2"
    local INT_NAME="$3"
    local IP="$4"

    echo "==> $CONTAINER : macvlan $MACVLAN_NAME -> $INT_NAME ($IP)"

    # Vérifier que le container existe
    if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
        echo "   ERREUR : container $CONTAINER introuvable (clab deploy fait ?)"
        return 1
    fi

    # Nettoyer si existe déjà (côté host)
    ip link del "$MACVLAN_NAME" 2>/dev/null || true

    # Nettoyer si existe déjà (côté container)
    PID=$(docker inspect -f '{{.State.Pid}}' "$CONTAINER")
    nsenter -t "$PID" -n ip link del "$INT_NAME" 2>/dev/null || true

    # Créer la macvlan sur l'interface physique de la VM
    ip link add "$MACVLAN_NAME" link "$HOST_IF" type macvlan mode bridge

    # Déplacer dans le namespace réseau du container
    ip link set "$MACVLAN_NAME" netns "$PID"

    # Renommer, configurer IP, activer
    nsenter -t "$PID" -n ip link set "$MACVLAN_NAME" name "$INT_NAME"
    nsenter -t "$PID" -n ip addr add "$IP" dev "$INT_NAME" 2>/dev/null || true
    nsenter -t "$PID" -n ip link set "$INT_NAME" up

    echo "   OK : $(nsenter -t "$PID" -n ip -4 addr show "$INT_NAME" | grep inet | head -1)"
}

echo "============================================"
echo "  Setup border links (macvlan sur $HOST_IF)"
echo "============================================"

# Vérifier que ens18 existe
if ! ip link show "$HOST_IF" >/dev/null 2>&1; then
    echo "ERREUR : interface $HOST_IF introuvable"
    echo "  Adapter HOST_IF dans ce script si l'interface s'appelle autrement"
    exit 1
fi

# Spine1 — patte vers le Catalyst (10.202.1.12, AS 65001)
setup_macvlan "${PREFIX}-spine1" "spine1-ext" "eth4" "$SPINE1_EXT_IP"

# Spine2 — patte vers le Mikrotik (10.202.1.13, AS 65001)
setup_macvlan "${PREFIX}-spine2" "spine2-ext" "eth4" "$SPINE2_EXT_IP"

echo ""
echo "=== Test connectivité L2 vers border routers ==="
PID1=$(docker inspect -f '{{.State.Pid}}' "${PREFIX}-spine1")
PID2=$(docker inspect -f '{{.State.Pid}}' "${PREFIX}-spine2")

echo -n "  spine1 (10.202.1.201) -> Catalyst (10.202.1.12) : "
nsenter -t "$PID1" -n ping -c1 -W2 10.202.1.12 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo -n "  spine2 (10.202.1.202) -> Mikrotik (10.202.1.13) : "
nsenter -t "$PID2" -n ping -c1 -W2 10.202.1.13 >/dev/null 2>&1 && echo "OK" || echo "FAIL"

echo ""
echo "=== Border links prêts. Les sessions eBGP vont monter. ==="
echo "  Vérifier : docker exec ${PREFIX}-spine1 vtysh -c 'show ip bgp summary'"

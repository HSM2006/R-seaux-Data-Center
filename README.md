# SAE DevCloud 4D01 — Réseaux Data Center

**Groupe** : Houssam + Binôme  
**Professeur** : BBP (Big Boss Pouchou)  
**Architecture** : Leaf & Spine EVPN/VXLAN, 2 datacenters, BGP inter-groupes

## Architecture globale

```
                    Réseau salle 10.202.0.0/16 (eBGP)
                         │                │
                   Catalyst 8000      Mikrotik
                   AS 65001 (iBGP)
                         │                │
                      Spine1          Spine2
                      AS 65100  ────  AS 65100
                    (Route Reflectors EVPN)
                    /    |    \    /    |    \
                 Leaf1 Leaf2 Leaf3  (VTEPs VXLAN VNI 10100)
                  |      |      |
              Services dans 172.20.1.0/24
```

## Structure du repo

```
dc1/                  # Datacenter 1 (Houssam — FRR)
  netlab/             # Topologie Netlab (netlab up)
  containerlab/       # Topologie Containerlab directe
    frr/bgp/          # Configs FRR underlay BGP
    frr/ospf/         # Configs FRR underlay OSPF (alternative prof)
  services/           # Stack services host (docker compose)
    observability/    # Prometheus + Grafana + gNMIc + sFlow
    nautobot/         # Source de vérité
  scripts/            # deploy.sh, setup-vtep.sh, check-bgp.sh...
dc2/                  # Datacenter 2 (Binôme — Arista cEOS)
docs/                 # Plan IP, architecture
```

## Déploiement rapide

```bash
# 1. Déployer le fabric (BGP underlay)
cd dc1 && sudo bash scripts/deploy.sh

# 2. Ou avec OSPF underlay (test prof)
sudo bash scripts/deploy.sh --ospf

# 3. Vérifier BGP + EVPN
bash scripts/check-bgp.sh

# 4. Stack observabilité
cd services/observability && docker compose up -d

# 5. Nautobot
cd services/nautobot && docker compose up -d
python3 ../scripts/populate-nautobot.py
```

## Config Catalyst (à faire une seule fois)

```
! Supprimer ancienne route
no ip route 10.202.1.0 255.255.255.128 10.202.0.60

! Nouvelle route vers services DC1
ip route 172.20.1.0 255.255.255.0 10.202.0.60

! Annonce BGP
router bgp 65001
 no network 10.202.1.0 mask 255.255.255.128
 network 172.20.1.0 mask 255.255.255.0
```

## Checklist BBP

- [ ] Validation Kanban
- [ ] Connectivité intra + inter-groupe (ping/traceroute)
- [ ] Image FRR custom buildée (dc1/frr-custom/Dockerfile)
- [ ] Test HA (spine down — convergence)
- [ ] VPN WireGuard
- [ ] Stack observabilité
- [ ] DNS unbound
- [ ] Web (nginx + HAProxy)
- [ ] Uptime-Kuma
- [ ] Oxidized → Git
- [ ] Nautobot (peuplé via API)
- [ ] LDAP/Samba AD

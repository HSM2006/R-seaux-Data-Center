# SAE DevCloud 4D01 : Réseaux Data Center

**Groupe** : Houssam, Soyf, Mouhamadi
**Professeur** : BBP (Big Boss Pouchou)
**Architecture** : trois datacenters Leaf & Spine en EVPN/VXLAN, interconnectés via une bordure BGP partagée (Catalyst 8000 + Mikrotik) et un tunnel VXLAN dédié entre deux des trois fabrics.

## Vue d'ensemble

```
                         Reseau de la salle 10.202.0.0/16 (eBGP)
                                 |                  |
                          Catalyst 8000          Mikrotik
                              AS 65001  --iBGP--  AS 65001
                                 |                  |
        +------------------------------------------------------------------+
        |                        |                        |               |
     DC1 (Houssam)           DC2 (Soyf)              DC3 (Mouhamadi)
     FRR, AS 65000           Arista cEOS, AS 65000   FRR, AS 65001
     iBGP + EVPN/VXLAN       iBGP + EVPN/VXLAN        OSPF + EVPN/VXLAN
     VNI 10100               VNI 10200 (services)     VNI 1010 (services)
                              VNI 1040 (DCI -> DC3)    VNI 1040 (DCI -> DC2, statique)
```

Chaque datacenter est un fabric leaf-spine independant, deploye et exploite par une seule personne. L'interconnexion entre les trois passe par deux boitiers physiques partages (Catalyst 8000 et Mikrotik, tous les deux en AS 65001, relies entre eux en iBGP), qui font chacun de l'eBGP vers le reseau commun de la salle et vers un fabric. En plus de cette bordure commune, Soyf (DC2) et Mouhamadi (DC3) ont etabli un tunnel VXLAN dedie entre leurs deux fabrics (VNI 1040), configure de maniere statique plutot que par EVPN multi-domaine.

## Structure du depot

```
DC1 - Houssam/         # Datacenter 1 (FRR)
  containerlab/         # Topologie deployee (iBGP + variante OSPF)
  evpn-vxlan/            # Doc de conception EVPN/VXLAN + variante eBGP non deployee
  frr-custom/            # Dockerfile de l'image FRR personnalisee
  scripts/               # deploy.sh, setup-vtep.sh, check-bgp.sh, iperf-test.sh...
  services/              # Stack services + observabilite (Prometheus/Grafana/SNMP)
  docs/                  # Notes de conception (underlay, BUM, observabilite)

DC2 - Soyf/             # Datacenter 2 (Arista cEOS)
  containerlab/           # Topologie + configs cEOS natives
  scripts/                # deploy.sh, install-frr.sh, check-bgp.sh
  services/               # Unbound
  telemetry/              # Chaine gNMI (Telegraf + Prometheus + Grafana)

DC3 - Mouhamadi/        # Datacenter 3 (FRR, via Netlab)
  node_files/             # Configs FRR/Linux generees par Netlab
  services/               # Web, DNS (images Docker personnalisees)
  external-configs/       # Exports Mikrotik/R1 personnels
  running-configs/        # Etat reel releve sur le lab
  archive/                # Sauvegardes horodatees + ancien materiel 2025

docs/                  # Plan d'adressage global
GUIDE-SOUTENANCE.md    # Commandes de preuve pour la soutenance (DC1)
RUNBOOK-observabilite.md
```

## Deploiement rapide (DC1)

```bash
cd "DC1 - Houssam"
sudo bash scripts/deploy.sh            # underlay iBGP (deploye)
sudo bash scripts/deploy.sh --ospf     # ou variante OSPF
bash scripts/check-bgp.sh
cd services/observability && docker compose up -d
```

Pour DC2 et DC3, voir les README respectifs de chaque dossier.

## Config Catalyst (bordure, a faire une seule fois)

```
! Nouvelle route vers les services DC1
ip route 172.20.1.0 255.255.255.0 10.202.0.60

! Annonce BGP
router bgp 65001
 network 172.20.1.0 mask 255.255.255.0
```

## Checklist BBP

- [x] Kanban (GitHub Projects v2)
- [x] Connectivite intra-groupe (ping/traceroute) sur les trois fabrics
- [x] Image FRR custom buildee (DC1)
- [x] Test HA (spine down, convergence BGP)
- [x] Stack observabilite (SNMP/AgentX + Prometheus + Grafana sur DC1, gNMI sur DC2)
- [x] DNS (Unbound sur les trois DC)
- [x] Web (nginx, + HAProxy sur DC1)
- [x] Oxidized -> Git (DC1)
- [x] Nautobot (script de peuplement pret, DC1)
- [x] Samba/AD ou annuaire (DC1, DC3)
- [x] Interconnexion VXLAN dediee DC2 <-> DC3
- [ ] VPN WireGuard / bastion Teleport (pas encore fait)
- [ ] Uptime-Kuma (optionnel, pas deploye partout)

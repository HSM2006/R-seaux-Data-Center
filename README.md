# SAE DevCloud 4D01 : Réseaux Data Center

**Groupe** : Houssam, Soyf, Mouhamadi
**Professeur** : BBP (Big Boss Pouchou)
**Architecture** : trois datacenters Leaf & Spine en EVPN/VXLAN, interconnectés via une bordure BGP en AS 65001 (deux boîtiers partagés entre DC1/DC2, deux boîtiers personnels pour DC3) et un tunnel VXLAN dédié entre DC2 et DC3.

## Vue d'ensemble

```
              Reseau de la salle 10.202.0.0/16 (eBGP)
                    |          |          |          |
             Catalyst 8000  Mikrotik  Catalyst    Mikrotik
              (partage)    (partage)  (Mouhamadi) (Mouhamadi)
              AS 65001     AS 65001   AS 65001    AS 65001
                  \           /           \           /
                   \--iBGP--/             \---iBGP---/
                       |                       |
                       +----------iBGP---------+
                       |                       |
              DC1 (Houssam)   DC2 (Soyf)   DC3 (Mouhamadi)
              FRR, AS 65000   Arista cEOS,  FRR, AS 65001
              iBGP+EVPN/VXLAN AS 65000      OSPF+EVPN/VXLAN
              VNI 10100       iBGP+EVPN     VNI 1010 (services)
                              VNI 10200     VNI 1040 (DCI->DC2,
                              VNI 1040       statique)
                              (DCI->DC3)
                                   |<-- VXLAN VNI 1040 -->|
```

DC1 (Houssam) et DC2 (Soyf) partagent deux boîtiers physiques communs : un Cisco Catalyst 8000 et un Mikrotik, tous deux en AS 65001, reliés entre eux en iBGP. DC3 (Mouhamadi) dispose de ses propres équipements de bordure : un Catalyst personnel et un Mikrotik personnel, également en AS 65001. Les quatre boîtiers se parlent en iBGP, formant une zone de transit commune : toute route annoncée par l'un des trois fabrics est redistribuée aux deux autres via cette bordure unifiée. En plus de ce routage BGP, Soyf (DC2) et Mouhamadi (DC3) ont établi un tunnel VXLAN dédié entre leurs deux fabrics (VNI 1040), configuré de manière statique plutôt que par EVPN multi-domaine.

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
  external-configs/       # Exports Mikrotik/Catalyst personnels
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

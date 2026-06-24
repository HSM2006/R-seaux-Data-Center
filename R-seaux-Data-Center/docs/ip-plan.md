# Plan d'adressage — SAE DevCloud 4D01 — Groupe HSM

## Blocs principaux

| Réseau | Usage | Qui |
|--------|-------|-----|
| `10.202.0.0/16` | Réseau salle — management, eBGP, liens physiques | Toute la classe |
| `172.16.0.0/24` | DC1 underlay — P2P /31 entre spines et leafs | Nous (interne fabric) |
| `172.16.255.0/24` | DC1 loopbacks /32 des routeurs | Nous (interne fabric) |
| `172.20.1.0/24` | DC1 services — web, DNS, AD, monitoring | Nous (annoncé en BGP) |
| `172.20.2.0/24` | DC2 services — binôme | Binôme (à confirmer via Nautobot) |

## Underlay DC1 (P2P /31)

| Lien | IP Spine | IP Leaf |
|------|----------|---------|
| spine1 ↔ leaf1 (eth1-eth1) | 172.16.0.0/31 | 172.16.0.1/31 |
| spine1 ↔ leaf2 (eth2-eth1) | 172.16.0.2/31 | 172.16.0.3/31 |
| spine1 ↔ leaf3 (eth3-eth1) | 172.16.0.4/31 | 172.16.0.5/31 |
| spine2 ↔ leaf1 (eth1-eth2) | 172.16.0.6/31 | 172.16.0.7/31 |
| spine2 ↔ leaf2 (eth2-eth2) | 172.16.0.8/31 | 172.16.0.9/31 |
| spine2 ↔ leaf3 (eth3-eth2) | 172.16.0.10/31 | 172.16.0.11/31 |

## Loopbacks

| Équipement | Loopback | Rôle BGP |
|------------|----------|---------|
| spine1 | 172.16.255.1/32 | AS 65100 — RR EVPN |
| spine2 | 172.16.255.2/32 | AS 65100 — RR EVPN |
| leaf1  | 172.16.255.11/32 | AS 65001 — VTEP |
| leaf2  | 172.16.255.12/32 | AS 65002 — VTEP |
| leaf3  | 172.16.255.13/32 | AS 65003 — VTEP |

## Services DC1 (172.20.1.0/24) — VNI 10100

| IP | Service | Leaf |
|----|---------|------|
| 172.20.1.10 | web1 (nginx) | leaf1 |
| 172.20.1.11 | web2 (nginx) | leaf2 |
| 172.20.1.12 | web3 (nginx) | leaf3 |
| 172.20.1.20 | dns1 (unbound) | leaf1 |
| 172.20.1.21 | dns2 (unbound) | leaf2 |
| 172.20.1.30 | samba/AD | leaf3 |
| 172.20.1.40 | haproxy (LB) | host |
| 172.20.1.50 | uptime-kuma | host |
| 172.20.1.60 | oxidized | host |
| 172.20.1.70 | nautobot | host |
| 172.20.1.80 | prometheus | host |
| 172.20.1.81 | grafana | host |
| 172.20.1.254 | **gateway** (veth-host sur br10100 leaf1) | host VM |

## Équipements physiques

| Équipement | IP management | AS BGP | Rôle |
|------------|--------------|--------|------|
| Catalyst 8000 | 10.202.0.12 (GigE2) | 65001 | Border eBGP + iBGP |
| Mikrotik | 10.255.255.1 | 65001 | Border eBGP + iBGP |
| VM Debian (Proxmox) | 10.202.0.60 | — | Hôte Containerlab |

## Règles BGP

- **eBGP** : Catalyst/Mikrotik ↔ réseau salle (autres groupes AS X00)
- **iBGP** : Catalyst ↔ Mikrotik (AS 65001)
- **eBGP underlay** : spines (65100) ↔ leafs (65001/65002/65003)
- **EVPN overlay** : BGP l2vpn evpn, spines = Route Reflectors
- **Annonce vers salle** : `172.20.1.0/24` via Catalyst (route statique → 10.202.0.60)

## Pourquoi 172.20.1.0/24 et pas 10.202.1.0/24

Le Catalyst a son interface GigabitEthernet2 en `10.202.1.12`, soit dans le bloc `10.202.1.0/24`.
Si les services sont dans ce même bloc, les containers pensent que le Catalyst est leur voisin L2
et ARPent directement → pas de réponse. En utilisant `172.20.1.0/24`, l'espace management
(`10.202.x.x`) et l'espace services (`172.20.x.x`) sont complètement séparés.

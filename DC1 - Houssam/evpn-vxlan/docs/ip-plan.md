# Plan IP complet

## Vue d'ensemble

| Zone | Réseau | Usage |
|---|---|---|
| Salle de classe | 10.202.0.0/16 | Réseau partagé entre tous les groupes |
| DC1 (moi) | 10.202.1.0/25 | Mes containers (VNI 10100) |
| DC2 (binôme) | 10.202.1.128/25 | Containers du binôme |
| Fabric DC1 underlay | 10.0.0.0/24 | Loopbacks routeurs DC1 |
| Liens leaf-spine | BGP unnumbered | Pas d'IP nécessaire |

## Loopbacks DC1

| Routeur | Loopback | Rôle |
|---|---|---|
| leaf1 | 10.0.0.1/32 | VTEP |
| leaf2 | 10.0.0.2/32 | VTEP |
| leaf3 | 10.0.0.3/32 | VTEP |
| spine1 | 10.0.0.101/32 | Transit + relais EVPN |
| spine2 | 10.0.0.102/32 | Transit + relais EVPN |

Ces loopbacks restent strictement internes au fabric. Elles ne sont jamais annoncées vers le réseau de la salle ni vers les autres groupes.

## Containers DC1 (VNI 10100)

Tous dans le subnet 10.202.1.0/25, peu importe le leaf physique.

| Container | IP | Leaf physique | Service |
|---|---|---|---|
| web1 | 10.202.1.10 | leaf1 | Web (HAProxy backend) |
| web2 | 10.202.1.11 | leaf2 | Web (HAProxy backend) |
| web3 | 10.202.1.12 | leaf3 | Web (HAProxy backend) |
| dns1 | 10.202.1.20 | leaf3 | Unbound HA #1 |
| dns2 | 10.202.1.21 | leaf3 | Unbound HA #2 |
| ad1 | 10.202.1.30 | leaf2 | Samba/AD primaire |
| ad2 | 10.202.1.31 | leaf2 | Samba/AD réplica |
| haproxy | 10.202.1.40 | leaf1 | LB + consul-template |
| consul | 10.202.1.50 | leaf1 | Service discovery |
| harbor | 10.202.1.60 | leaf2 | Registry containers |

La beauté de l'archi single-VNI : si demain je veux migrer dns1 du leaf3 au leaf1, l'IP ne change pas, je débranche le container du bridge de leaf3 et je le rebranche sur celui de leaf1, EVPN propage la nouvelle MAC/VTEP automatiquement.

## AS BGP

| Composant | AS | Type session |
|---|---|---|
| leaf1 | 65001 | eBGP vers spines, EVPN |
| leaf2 | 65002 | eBGP vers spines, EVPN |
| leaf3 | 65003 | eBGP vers spines, EVPN |
| spine1 | 65100 | eBGP vers leafs, EVPN |
| spine2 | 65100 | eBGP vers leafs, EVPN |
| Catalyst (border DC1) | 65001 | iBGP avec Mikrotik, eBGP avec les autres groupes |
| Mikrotik (border DC2) | 65001 | iBGP avec Catalyst, eBGP avec les autres groupes |

Note : les spines partagent le même AS 65100, c'est volontaire. Ça évite que les leafs apprennent les routes du voisin via les deux spines avec un AS-path différent et que ça crée des chemins asymétriques bizarres.

## Annonces BGP

### Underlay (interne fabric)
- Chaque leaf annonce sa loopback /32 aux spines
- Chaque spine annonce sa loopback /32 et les loopbacks apprises aux autres leafs
- Résultat : tous les leafs et spines connaissent toutes les loopbacks

### Overlay EVPN (interne fabric)
- Chaque leaf annonce les MAC/IP de ses containers locaux
- Les spines relaient sans changer le next-hop
- Résultat : chaque leaf sait derrière quel VTEP se trouve chaque container

### Externe (vers la salle)
- Catalyst annonce 10.202.1.0/25 vers le réseau de la salle (eBGP)
- Catalyst reçoit les /25 des autres groupes
- Mikrotik fait pareil de son côté pour 10.202.1.128/25

## Déclaration Nautobot

Chaque container est déclaré dans Nautobot via l'API Python avec :
- Son IP
- Le préfixe parent (10.202.1.0/25)
- Un tag indiquant le VNI (10100)
- Le leaf physique de rattachement (pour info)

Script à faire côté automatisation : `scripts/populate-nautobot.py`.

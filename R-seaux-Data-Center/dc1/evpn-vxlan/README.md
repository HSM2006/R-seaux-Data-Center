# EVPN / VXLAN fabric — DC1

Ce dossier contient la migration du fabric L3 vers une archi EVPN/VXLAN avec un seul VNI partagé entre les trois leafs.

## Pourquoi on change

Avant, chaque leaf était un subnet séparé et les containers communiquaient via routage L3 classique. Du coup deux containers branchés sur deux leafs différents devaient passer par le routage, et changer de leaf voulait dire changer d'IP.

Maintenant on veut que tous nos containers soient dans le même réseau L2, peu importe le leaf sur lequel ils tournent. C'est ce que fait VXLAN : il encapsule des trames Ethernet dans de l'UDP (port 4789) pour les transporter à travers le fabric IP.

Le control plane qui distribue les infos MAC/IP entre les leafs c'est MP-BGP EVPN, une address-family BGP dédiée (`l2vpn evpn`).

## Architecture

```
Réseau salle 10.202.0.0/16  (eBGP inter-groupes)
        │                │
   Catalyst 8000    Mikrotik
   (iBGP, AS 65001 partagé entre les deux)
        │                │
        └────┬───────┬───┘
             │       │
         Spine1   Spine2          AS 65100
         (relais EVPN, pas VTEP)
          │ │ │   │ │ │
          │ │ │   │ │ │
        Leaf1   Leaf2   Leaf3     AS 65001 / 65002 / 65003
         VTEP    VTEP    VTEP
          │       │       │
       containers tous dans VNI 10100
       même subnet 10.202.1.0/25
```

Les **spines** ne sont pas VTEPs. Ils transportent juste les paquets VXLAN entre les leafs et relaient les annonces EVPN.

Les **leafs** sont les VTEPs (VXLAN Tunnel Endpoints). Ils encapsulent/décapsulent le trafic et annoncent leurs containers locaux en EVPN.

## Choix techniques

### Single VNI 10100
Un seul VNI pour tout le DC1. Tous les containers (web, DNS, AD) sont dans le même domaine de broadcast. Si un container web sous leaf1 ping un container DNS sous leaf3, c'est du pur L2 étendu via VXLAN, pas de routage inter-VNI.

Du coup pas besoin de symmetric/asymmetric routing, pas besoin de VRF EVPN, pas besoin de VNI L3 de transit. On reste sur du L2 bridging pur, c'est le cas le plus simple qui marche.

### Vendors
- Moi : FRR sur tous mes leafs et spines de DC1
- Mon binôme : Arista cEOS sur ses leafs/spines de DC2
- Les deux fabrics parlent EVPN entre eux via les border routers

### Underlay vs Overlay
- **Underlay** : BGP IPv4 unicast entre leafs et spines. Annonce uniquement les loopbacks (10.0.0.x/32). C'est l'autoroute qui transporte les paquets VXLAN.
- **Overlay** : BGP EVPN (l2vpn evpn) entre leafs et spines. Transporte les annonces MAC/IP des containers. Le next-hop reste la loopback du leaf source (option `next-hop-unchanged` côté spine).

## Plan IP

| Element | Réseau | Détail |
|---|---|---|
| Loopbacks leafs | 10.0.0.1, 10.0.0.2, 10.0.0.3 /32 | VTEP IPs |
| Loopbacks spines | 10.0.0.101, 10.0.0.102 /32 | route reflectors EVPN |
| Liens leaf-spine | 172.16.x.0/30 | jamais annoncés en BGP externe |
| Containers DC1 | 10.202.1.0/25 | VNI 10100, déclaré dans Nautobot |
| Containers DC2 | 10.202.1.128/25 | géré par le binôme |

## Intégration Nautobot

Chaque container a une IP unique dans le /25 de son DC. On déclare ces IPs dans Nautobot via l'API Python pour que tous les groupes de la classe sachent qui héberge quoi. Le préfixe 10.202.1.0/25 est ensuite annoncé en eBGP par le Catalyst vers le réseau de la salle, ce qui permet aux autres groupes de joindre nos containers.

## Contenu du dossier

```
evpn-vxlan/
├── README.md                  # Ce fichier
├── ROADMAP.md                 # Ce qu'il reste à faire
├── configs/
│   ├── topology.clab.yml      # Topologie Containerlab à jour
│   ├── frr/                   # Configs FRR (leafs + spines)
│   └── linux/                 # Scripts setup bridge + VXLAN
└── docs/
    ├── architecture.md        # Détails du flux EVPN
    └── ip-plan.md             # Plan d'adressage complet
```

## Comment tester

1. Build de l'image FRR custom (déjà fait) : `docker build -t frrouting/frr:latest ~/frr-custom/`
2. Déploiement topologie : `cd configs/ && sudo clab deploy -t topology.clab.yml`
3. Setup VXLAN sur chaque leaf : `bash linux/setup-vtep.sh leaf1`
4. Vérifier BGP underlay : `docker exec clab-dc1-leaf1 vtysh -c "show bgp summary"`
5. Vérifier EVPN : `docker exec clab-dc1-leaf1 vtysh -c "show bgp l2vpn evpn"`
6. Ping inter-leaf depuis un container : `docker exec container-web1 ping 10.202.1.20`

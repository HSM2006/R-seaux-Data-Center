# DevCloud Leaf-Spine FRR EVPN/VxLAN

Ce lab netlab/containerlab deploie une fabric Leaf-Spine avec 2 spines, 3 leafs et 4 services Linux. Les routeurs reseau sont tous en FRR. L'underlay utilise OSPF, l'overlay prepare EVPN/VxLAN L2 avec VLAN 10 et VNI 1010, sans VRF.

## Plan d'adressage

- Liens Leaf-Spine: `10.25.0.0/24`, decoupes en `/30` de `10.25.0.0/30` a `10.25.0.20/30`.
- Services: `10.25.0.24/29`.
- Loopbacks: `10.255.0.0/24`, une loopback `/32` par routeur.

| Noeud | Adresse |
| --- | --- |
| spine1 | 10.255.0.254/32 |
| spine2 | 10.255.0.253/32 |
| leaf1 | 10.255.0.1/32 |
| leaf2 | 10.255.0.2/32 |
| leaf3 | 10.255.0.3/32 |
| web1 | 10.25.0.25/29 |
| annuaire | 10.25.0.26/29 |
| dns1 | 10.25.0.27/29 |
| web2 | 10.25.0.28/29 |

## Lancer le lab

Sur la VM, activer netlab si necessaire, construire les images locales de services, puis lancer le lab:

```bash
export PATH=/root/.pyenv/versions/netlab/bin:$PATH
docker build -t devcloud-web:latest services/web
docker build -t devcloud-unbound:latest services/unbound
netlab up
```

Arreter et nettoyer:

```bash
netlab down
```

Se connecter a des noeuds:

```bash
netlab connect leaf1
netlab connect spine1
netlab connect web1
```


## Lien externe host/ens18

`spine1` possede un lien externe sur `eth4` avec l'adresse `172.7.0.3/29`.
Dans `topology.yml`, ce lien est decrit avec `clab.uplink: ens18`; netlab genere alors dans `clab.yml` un endpoint `macvlan:ens18`.
Containerlab affiche ce lien comme `host:ens18 <--> spine1:eth4` au deploiement. La syntaxe litterale `host:ens18` dans `clab.yml` n'est pas utilisee, car elle tente de creer une interface hote `ens18` et echoue si `ens18` existe deja.

Verification:

```bash
docker exec clab-devcloudevpn-spine1 ip -br a show eth4
docker exec clab-devcloudevpn-spine1 vtysh -c 'show interface eth4'
```

## Verifier OSPF

Depuis un routeur FRR:

```text
show ip ospf neighbor
show ip route ospf
```

Les leafs doivent voir les deux spines comme voisins OSPF. Les loopbacks `10.255.0.x/32` doivent etre joignables via OSPF.

## Verifier BGP et EVPN

Depuis un spine ou un leaf:

```text
show bgp summary
show bgp l2vpn evpn summary
show bgp l2vpn evpn
```

Les spines jouent le role de Route Reflector EVPN. Les leafs sont les VTEP et portent le VLAN/VNI de services.

## Verifier VxLAN

Depuis un leaf FRR:

```text
show evpn vni
show evpn mac vni all
```

Depuis le shell Linux du conteneur leaf:

```bash
ip -br a
ip -d link show type vxlan
bridge link
bridge fdb show
tcpdump -ni any udp port 4789
```

## Tester les services

Depuis les containers Linux ou depuis un noeud ayant acces au VLAN de services:

```bash
ping -c 3 10.25.0.25
ping -c 3 10.25.0.26
ping -c 3 10.25.0.27
ping -c 3 10.25.0.28
curl http://10.25.0.25
curl http://10.25.0.28
dig @10.25.0.27 mouhamadi.local
```

La page `web1` doit afficher:

```text
site web mouhamadi
```

## Notes de conception

- Aucun VRF n'est configure dans cette premiere version.
- Les spines ne sont pas VTEP: ils participent a OSPF/BGP/EVPN uniquement.
- Les leafs sont les VTEP et etendent le VLAN `services` via le VNI `1010`.
- Le reseau services est un segment L2 commun `10.25.0.24/29`.

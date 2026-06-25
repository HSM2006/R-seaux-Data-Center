# Trafic BUM dans le fabric EVPN (optionnel)

BUM = **B**roadcast, **U**nknown unicast, **M**ulticast. Dans un L2 classique
ça part en flooding. En EVPN/VXLAN, on ne floode pas n'importe comment : chaque
VTEP apprend qui sont les autres VTEP du VNI via les **routes EVPN type-3**
(Inclusive Multicast Ethernet Tag) et réplique le BUM uniquement vers eux.
C'est l'**ingress replication** (réplication à la source).

## On n'a rien à configurer en plus

Avec `advertise-all-vni` (déjà présent sur les leafs), FRR génère
automatiquement les routes type-3 pour le VNI 10100. L'ingress replication est
donc déjà active. Le prof a dit que c'est à voir "après" : pas de blocage, c'est
juste de l'observation.

## Comment l'observer

```bash
# Les routes type-3 (un VTEP par leaf qui s'annonce sur le VNI)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show bgp l2vpn evpn route type multicast"

# Détail du VNI : liste des VTEP distants pour la réplication BUM
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn vni detail"

# La table de flood (têtes de tunnel VXLAN vers les autres leafs)
docker exec clab-dc1-evpn-leaf1 bridge fdb show dev vxlan10100 | grep 00:00:00:00:00:00
```

## Démo simple du BUM

Un `ping` vers une IP jamais vue déclenche d'abord un ARP (broadcast = BUM) :

```bash
# Vider le cache ARP puis pinguer -> l'ARP part en BUM, répliqué vers les VTEP
docker exec clab-dc1-evpn-web1 ip neigh flush all
docker exec clab-dc1-evpn-web1 ping -c 2 172.20.1.12
# En parallèle, capturer le VXLAN sur un spine montre l'encapsulation
docker exec clab-dc1-evpn-spine1 tcpdump -ni any udp port 4789 -c 5
```

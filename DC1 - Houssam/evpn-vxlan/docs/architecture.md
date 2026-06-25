# Architecture détaillée — flux EVPN/VXLAN

## Les deux plans à bien séparer

### Plan de données (data plane) : VXLAN
C'est ce qui transporte les paquets utilisateur. Quand un container envoie une trame Ethernet à un autre container, le leaf source l'encapsule dans un paquet UDP (port 4789) et l'envoie via le réseau IP du fabric. Le leaf destination décapsule et livre la trame originelle.

Le tunnel VXLAN existe entre toutes les paires de leafs (full mesh logique). Les spines ne participent pas, ils transportent juste les paquets UDP en pur routage IP.

### Plan de contrôle (control plane) : MP-BGP EVPN
C'est ce qui dit aux leafs "le container avec la MAC aa:bb:cc:dd:ee:ff et l'IP 10.202.1.10 est derrière le VTEP 10.0.0.1". Sans ça, les leafs ne sauraient pas où envoyer le trafic.

EVPN c'est une address-family BGP (`l2vpn evpn`) qui transporte différents types d'annonces. Pour notre cas avec un seul VNI, les routes importantes sont :

- **Type-2 (MAC/IP advertisement)** : chaque leaf annonce les MAC + IP de ses containers locaux. Les autres leafs apprennent qu'ils peuvent les joindre via le VTEP source.
- **Type-3 (Inclusive Multicast)** : chaque leaf dit "j'existe en tant que VTEP du VNI 10100". Sert au BUM (Broadcast, Unknown unicast, Multicast).

## Cheminement d'un ping

Scénario : `web1` (10.202.1.10 sous leaf1) ping `dns1` (10.202.1.20 sous leaf3).

```
1. web1 émet un ARP "qui a 10.202.1.20 ?"
   La trame arrive sur leaf1 via le bridge br10100.

2. leaf1 a déjà appris (via EVPN type-2) que la MAC de 10.202.1.20
   est joignable via le VTEP 10.0.0.3 (loopback de leaf3).
   Il répond à l'ARP directement (ARP suppression EVPN) ou il
   forwarde la requête.

3. web1 envoie le paquet ICMP à la MAC de dns1.

4. leaf1 récupère la trame, voit la MAC dest, lookup la table EVPN :
   → next-hop VTEP = 10.0.0.3
   Il encapsule la trame dans VXLAN avec VNI=10100, IP dest=10.0.0.3.

5. Le paquet VXLAN traverse spine1 ou spine2 (ECMP). Les spines
   font du pur routage IP basé sur la destination 10.0.0.3.

6. leaf3 reçoit le paquet VXLAN, le décapsule, retrouve la trame
   originelle, la livre à dns1 via le bridge br10100.

7. Retour identique en sens inverse.
```

## Underlay vs overlay : pourquoi deux address-families

C'est le point qui m'a le plus perturbé au début. Pourquoi BGP en double ?

- **Underlay (IPv4 unicast)** sert à ce que tous les leafs sachent comment joindre les loopbacks des autres leafs. Sans ça, le paquet VXLAN ne peut pas être routé vers son VTEP destination. C'est l'autoroute en dessous.

- **Overlay (l2vpn evpn)** sert à apprendre quel container est derrière quel VTEP. C'est ce qui dit "pour joindre 10.202.1.20, encapsule vers 10.0.0.3".

Les deux passent dans la même session BGP, juste deux address-families différentes. Une session BGP par lien leaf-spine, deux AF par session.

## Le piège du next-hop en eBGP EVPN

En eBGP classique, quand un routeur transit annonce une route à un voisin, il remplace le next-hop par sa propre IP. C'est le comportement par défaut.

Dans notre cas, ça serait catastrophique : si le spine1 annonce la route EVPN de web1 à leaf3 en mettant son propre IP comme next-hop, alors leaf3 va encapsuler le VXLAN à destination du spine1, qui n'est pas VTEP et ne saura pas quoi en faire.

Solution : sur les spines, on force `set ip next-hop unchanged` pour l'AF EVPN. Comme ça le next-hop reste la loopback du leaf source, et l'encapsulation VXLAN cible le bon VTEP.

Côté FRR c'est le `route-map NEXTHOP-UNCHANGED` appliqué en out sur le peer-group LEAFS.

## Intégration avec le DC2 et les autres groupes

Le fabric EVPN s'arrête à mes border routers (Catalyst et Mikrotik). Vers l'extérieur (DC2 du binôme, autres groupes de la classe), je n'annonce pas l'EVPN, j'annonce juste le préfixe agrégé 10.202.1.0/25 en eBGP IPv4 classique.

Pourquoi ? Parce que :
- Le DC2 est un fabric EVPN séparé (avec son propre VNI sans doute)
- Les autres groupes n'ont pas forcément d'EVPN, ils attendent du BGP IPv4 classique
- On reste interopérable avec tout le monde

```
Mon DC1 (EVPN interne, VNI 10100)
  → border routers (Catalyst + Mikrotik)
     → eBGP IPv4 standard
        → DC2 binôme + autres groupes
```

L'EVPN reste donc une affaire purement interne au DC.

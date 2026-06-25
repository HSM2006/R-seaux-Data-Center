# Underlay numéroté (numbered)

Le prof a demandé un underlay **numbered** (adresses IP explicites sur les liens
et voisins BGP par IP), par opposition au BGP *unnumbered* (peering par interface).

## C'est déjà le cas dans la config déployée

La topologie active (`dc1/containerlab/topology.clab.yml`) bind les configs
`dc1/containerlab/frr/bgp/*.conf`, qui sont **entièrement numérotées** :

- Chaque lien leaf-spine a une IP /31 explicite (plan dans `docs/ip-plan.md`).
- Chaque session BGP est déclarée par IP de loopback, pas par interface.

Exemple sur leaf1 :

```
interface eth1
 ip address 172.16.0.1/31        <- IP explicite sur le lien
!
router bgp 65000
 neighbor 172.16.255.1 remote-as 65000     <- voisin par IP (spine1)
 neighbor 172.16.255.1 update-source lo
 neighbor 172.16.255.2 remote-as 65000     <- voisin par IP (spine2)
```

(La variante *unnumbered* — `neighbor eth1 interface peer-group SPINES` — existe
seulement dans l'ancien dossier `dc1/evpn-vxlan/`, qui n'est plus déployé.)

## Vérification

```bash
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"
docker exec clab-dc1-evpn-leaf1 vtysh -c "show run" | grep -A2 "interface eth"
```

Les `Neighbor` affichés sont des IP (172.16.255.1, 172.16.255.2) -> underlay numéroté.

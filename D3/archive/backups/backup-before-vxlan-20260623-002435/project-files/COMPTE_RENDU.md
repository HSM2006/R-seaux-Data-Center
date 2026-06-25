# Compte rendu - Generation du lab DevCloud FRR EVPN/VxLAN

## Contexte

Le travail a ete realise directement sur la VM cible `10.202.0.248`, connectee en SSH avec l'utilisateur `root`, comme demande. Le depot GitHub `https://github.com/pushou/SAE_devCloud_D01` n'etait pas present dans `/root`, il a donc ete clone dans `/root/SAE_devCloud_D01`.

## Actions realisees

1. Inspection de la VM et du depot.
   - Verification du repertoire courant avec `pwd`.
   - Liste des fichiers avec `ls` et `find`.
   - Lecture du `README.md` existant.

2. Verification de l'environnement netlab.
   - `netlab` est installe via pyenv dans `/root/.pyenv/versions/netlab/bin`.
   - Version observee: `netlab 26.06`.
   - Les modules `ospf`, `bgp`, `evpn`, `vxlan` et `vlan` sont supportes par FRR.

3. Generation de l'infrastructure.
   - Creation de `topology.yml`.
   - Creation de `README.md` oriente exploitation du lab.
   - Creation des fichiers de services dans `services/`.
   - Creation de ce compte rendu `COMPTE_RENDU.md`.

## Topologie produite

La fabric contient:

- 2 spines: `spine1`, `spine2`.
- 3 leafs: `leaf1`, `leaf2`, `leaf3`.
- 4 services Linux: `web1`, `annuaire`, `dns1`, `web2`.

Chaque leaf est connecte a chaque spine. Les liens Leaf-Spine sont des liens L3 point-a-point en `/30` dans `10.25.0.0/24`.

## Plan d'adressage applique

| Usage | Prefixe |
| --- | --- |
| Leaf-Spine | 10.25.0.0/24 decoupe en /30 |
| Services | 10.25.0.24/29 |
| Loopbacks | 10.255.0.0/24 decoupe en /32 |

Loopbacks:

| Noeud | Loopback |
| --- | --- |
| spine1 | 10.255.0.254/32 |
| spine2 | 10.255.0.253/32 |
| leaf1 | 10.255.0.1/32 |
| leaf2 | 10.255.0.2/32 |
| leaf3 | 10.255.0.3/32 |

Services:

| Service | IP |
| --- | --- |
| web1 | 10.25.0.25/29 |
| annuaire | 10.25.0.26/29 |
| dns1 | 10.25.0.27/29 |
| web2 | 10.25.0.28/29 |

## Choix techniques

- FRR est utilise pour tous les equipements reseau.
- OSPF assure l'underlay et la joignabilite des loopbacks/VTEP.
- BGP EVPN prepare l'overlay.
- Les spines sont Route Reflector EVPN.
- Les leafs sont les seuls VTEP.
- VLAN 10 et VNI 1010 transportent les services en L2.
- Aucun VRF n'est configure.

## Fichiers crees ou modifies

- `topology.yml`: topologie netlab principale, commentee.
- `README.md`: procedure de lancement et de verification.
- `services/web1/index.html`: page web affichant `site web mouhamadi`.
- `services/web2/index.html`: page de verification du second serveur web.
- `services/unbound/unbound.conf`: configuration Unbound minimale pour `mouhamadi.local`.
- `services/web/Dockerfile`: image web locale avec Python, curl, dig et iproute2.
- `services/unbound/Dockerfile`: image DNS locale avec Unbound et bind-tools.
- `COMPTE_RENDU.md`: synthese des actions realisees.

## Verifications prevues

Les commandes de verification sont documentees dans `README.md`:

- OSPF: `show ip ospf neighbor`, `show ip route ospf`.
- BGP: `show bgp summary`.
- EVPN: `show bgp l2vpn evpn summary`, `show bgp l2vpn evpn`.
- VxLAN: `show evpn vni`, `show evpn mac vni all`, `ip -d link show type vxlan`.
- Services: `curl http://10.25.0.25`, `curl http://10.25.0.28`, `dig @10.25.0.27 mouhamadi.local`.

## Corrections pendant validation

Pendant le premier lancement, trois ajustements ont ete faits:

- Le nom netlab initial a ete raccourci en `devcloudevpn` pour respecter les contraintes d'identifiant netlab et eviter les avertissements DNS containerlab lies aux underscores.
- Les serveurs web utilisent maintenant l'image locale `devcloud-web:latest`, construite depuis `services/web/Dockerfile`, avec `curl`, `dig` et `iproute2` disponibles pour les tests.
- Le DNS utilise l'image locale `devcloud-unbound:latest`, construite depuis `services/unbound/Dockerfile`, afin de ne pas installer Unbound au demarrage du conteneur.

## Validation effectuee sur la VM

Le lab a ete lance avec succes depuis `/root/SAE_devCloud_D01` avec `netlab up`. L'ancien lab netlab actif dans `/root/sae-evpn-vxlan` a ete arrete apres accord utilisateur.

Resultats observes:

- `show ip ospf neighbor` sur `leaf1`: voisins `spine1` et `spine2` en etat `Full`.
- `show bgp summary` sur `spine1`: 4 peers iBGP etablis (`spine2`, `leaf1`, `leaf2`, `leaf3`).
- `show bgp l2vpn evpn summary` sur `spine1`: sessions EVPN etablies avec les leafs.
- `show evpn vni` sur `leaf1`: VNI `1010` de type L2 avec 2 VTEP distants.
- `ip -br a` sur `web1`: adresse service `10.25.0.25/29` presente sur `eth1`.
- Ping `web1 -> web2`: 0% de perte vers `10.25.0.28`.
- `curl http://10.25.0.25`: reponse `site web mouhamadi`.
- `curl http://10.25.0.28`: reponse `web2 devcloud ok`.
- `dig @10.25.0.27 mouhamadi.local +short`: reponse `10.25.0.25`.

Etat final: le lab `default` est demarre dans `/root/SAE_devCloud_D01` avec le provider `clab`.

## Diagramme Draw.io

Un diagramme editable Draw.io a ete ajoute:

- `diagramme_infra_ips.drawio`
- `diagramme_infra_ips.io`

Il represente les 2 spines, les 3 leafs, les 4 services, les loopbacks, les sous-reseaux `/30`, le reseau services `/29`, ainsi que les suffixes IP par interface comme `.1`, `.2`, `.25`, etc.

## Modification AS 65001 et router-id

A la demande utilisateur, le lab actif a ete detruit puis la topologie a ete modifiee:

- AS BGP global: `65001`.
- `spine1`: loopback/router-id OSPF/BGP `10.255.0.254/32`.
- `spine2`: loopback/router-id OSPF/BGP `10.255.0.253/32`.
- `leaf1`: loopback/router-id OSPF/BGP `10.255.0.1/32`.
- `leaf2`: loopback/router-id OSPF/BGP `10.255.0.2/32`.
- `leaf3`: loopback/router-id OSPF/BGP `10.255.0.3/32`.
- Les deux spines restent Route Reflector EVPN.

Validation apres modification AS 65001:

- `netlab up` termine correctement.
- `spine1` utilise `router bgp 65001`, `bgp router-id 10.255.0.254`, `bgp cluster-id 10.255.0.254` et `ospf router-id 10.255.0.254`.
- `spine2` utilise `router bgp 65001`, `bgp router-id 10.255.0.253`, `bgp cluster-id 10.255.0.253` et `ospf router-id 10.255.0.253`.
- Les leafs voient les spines en voisins OSPF `Full` avec router-id `10.255.0.254` et `10.255.0.253`.
- Les sessions BGP EVPN sont etablies en AS `65001`.
- Les tests applicatifs `curl` et `dig` restent fonctionnels.


## Ajout du lien externe vers ens18

Le lab a ete detruit puis reconstruit avec un lien externe sur `spine1`:

- `spine1:eth4` porte l'adresse `172.7.0.3/29`.
- Le lien est raccorde au reseau de l'hote via `ens18`.
- La syntaxe operationnelle dans netlab est `clab.uplink: ens18`, qui genere `macvlan:ens18` dans `clab.yml`.
- Containerlab confirme au demarrage: `Creating MACVLAN link: host:ens18 <--> spine1:eth4`.
- La syntaxe litterale `host:ens18` a ete evitee car containerlab tente alors de creer une interface hote nommee `ens18`, ce qui echoue si l'interface existe deja.

Validation:

- `spine1 eth4`: `UP`, `172.7.0.3/29`.
- OSPF leaf-spine: voisins `Full`.
- BGP EVPN AS `65001`: sessions etablies.
- Services web et DNS toujours fonctionnels.
- Interface hote `ens18` toujours UP avec `10.202.0.248/16`.

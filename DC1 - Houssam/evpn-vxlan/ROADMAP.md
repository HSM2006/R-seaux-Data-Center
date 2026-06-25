# ROADMAP — ce qu'il reste à faire

État au 15 juin 2026.

## Étape actuelle : migration EVPN/VXLAN

- [x] Décision archi single VNI (10100) validée
- [x] Configs FRR leafs + spines rédigées (commit en cours)
- [x] Script setup-vtep.sh prêt
- [x] Topologie Containerlab à jour
- [ ] Déploiement de la topologie sur la VM Debian
- [ ] Validation BGP underlay (toutes les loopbacks visibles partout)
- [ ] Validation EVPN (routes type-2 et type-3 visibles dans `show bgp l2vpn evpn`)
- [ ] Ping inter-leaf entre containers dans le même VNI
- [ ] Test de mobilité : déplacer un container d'un leaf à un autre sans changer son IP

## Avant ça : résoudre le blocage iptables FORWARD

Le ping inter-leaf de la phase précédente était bloqué par la FORWARD chain de la VM Debian. Le fix tenté (`iptables -P FORWARD ACCEPT` + `iptables -I DOCKER-USER -j ACCEPT`) n'a pas été confirmé. À refaire avant de déployer la nouvelle topo, sinon EVPN ne donnera rien de mieux.

Persister le fix dans `/etc/iptables/rules.v4` ou un script systemd pour qu'il survive au reboot.

## En parallèle : tâches non liées à EVPN

### Border routers (déjà entamé)
- [x] iBGP Catalyst ↔ Mikrotik établi
- [ ] Annoncer 10.202.1.0/25 vers les autres groupes en eBGP
- [ ] Recevoir les /25 des autres groupes et les vérifier
- [ ] Documenter le mapping AS-groupe (qui est AS 65014, 65080, etc.)

### Phase Arista cEOS (côté binôme)
- [ ] Le binôme build/setup son fabric DC2 avec cEOS
- [ ] Configs équivalentes EVPN sur cEOS (syntaxe différente de FRR)
- [ ] Validation BGP entre nos deux DC via les border routers
- [ ] Test de joignabilité depuis un container DC1 vers un container DC2

### Services applicatifs
- [ ] DNS Unbound x2 en HA (VIP via keepalived ou DNS round-robin)
- [ ] Samba/AD primaire + réplica
- [ ] HAProxy + consul-template pour le LB des webs
- [ ] Consul pour la service discovery
- [ ] Harbor comme registry privé
- [ ] Portainer ou Rancher pour le management des containers

### Sécurité
- [ ] WireGuard pour l'accès au management
- [ ] Teleport comme bastion SSH

### Observabilité (stack obligatoire)
- [ ] gNMIc pour la télémétrie streaming depuis les routeurs
- [ ] sFlow pour le sampling du trafic
- [ ] Prometheus pour la collecte
- [ ] Grafana pour la visualisation
- [ ] Dashboard avec au moins : sessions BGP, débit par leaf, état VXLAN

### Source de vérité
- [ ] Nautobot peuplé via API Python avec tous les équipements
- [ ] Tous les containers DC1 déclarés avec leur IP et VNI
- [ ] Coordination avec les autres groupes pour qu'ils peuplent aussi

### Automatisation
- [ ] Playbook Ansible de déploiement des containers
- [ ] Script Python de population Nautobot
- [ ] Oxidized configuré pour backup les configs vers un repo Git

## Tests à faire valider par le BBP

- [ ] HA de l'infrastructure IP : couper un leaf, vérifier que le trafic continue via les autres
- [ ] HA de l'infrastructure IP : couper un spine, vérifier ECMP
- [ ] Test de charge sur les services Web depuis un client externe
- [ ] Joignabilité depuis un autre groupe vers nos services
- [ ] Multi-vendor effectif (FRR côté moi, cEOS côté binôme, communication OK)
- [ ] Stack d'observabilité fonctionnelle (alerte BGP down détectée par exemple)

## Rapport final

À ne pas oublier en fin de projet :
- Rapport synthétique 1 fiche = 1 action, **sans contenu LLM**
- Bilan en camemberts du travail de chacun (Qui ? Quoi ? Commits ? Durée ? Résultats)
- Tout dans le repo Git fourni par le BBP
- Soutenance orale à préparer

## Jalons BBP restant à valider

- [ ] Validation du choix EVPN single VNI
- [ ] Validation S&L (Spine & Leaf) avec EVPN qui tourne
- [ ] Validation sauvegardes (Oxidized)
- [ ] Validation Serveurs de fichiers (Samba/AD)
- [ ] Validation BGP intergroupes
- [ ] Validation Nautobot peuplé
- [ ] Validation VPN (WireGuard)
- [ ] Validation stack de télémétrie
- [ ] Validation interconnexion avec un autre groupe (autre que le binôme)
- [ ] Validation tests de charge
- [ ] Validation finale du nombre et qualité de services containerisés

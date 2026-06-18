# Guide de validation / soutenance — SAE DevCloud 4D01 (DC1)

Toutes les commandes pour prouver que chaque brique fonctionne, le jour de la
soutenance. A lancer depuis la VM (`~/R-seaux-Data-Center`).

Conteneurs nommes `clab-dc1-evpn-<noeud>`. IP de management fixes :
leaf1=172.20.20.11, leaf2=.12, leaf3=.13, spine1=.101, spine2=.102.
SNMP sur le port **10161**.

---

## 0. Déploiement complet (point de départ)

```bash
docker build -t frrouting/frr:latest dc1/frr-custom/   # image FRR custom (FRR+snmpd+iperf3)
sudo bash dc1/scripts/deploy.sh                          # fabric + VXLAN + verifs
( cd dc1/services/observability && docker compose up -d )# Prometheus/Grafana/exporters
```

`docker ps` doit montrer 11 conteneurs clab + 4 conteneurs d'observabilité.

---

## 1. Underlay BGP (numbered, single-AS + Route Reflectors)

```bash
# Toutes les sessions iBGP doivent etre Established (pas Active/Connect)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"

# Toutes les loopbacks /32 apprises partout (172.16.255.1,2,11,12,13)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip route bgp"

# Cote spine = Route Reflector : voir les clients RR
docker exec clab-dc1-evpn-spine1 vtysh -c "show ip bgp summary"
```
**Ce qu'on montre :** underlay IPv4 numerote, AS 65000 unique, spines = RR, full-mesh L&S.

---

## 2. Overlay EVPN / VXLAN (VNI 10100)

```bash
# Le VNI 10100 est actif, type L2, avec 2 VTEP distants vus par chaque leaf
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn vni"

# Routes EVPN : type-2 (MAC/IP des conteneurs) + type-3 (chaque VTEP du VNI)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show bgp l2vpn evpn"

# Les MAC distantes apprises via BGP (control plane), pas par flooding
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn mac vni 10100"

# Cote kernel : le device VXLAN et le bridge
docker exec clab-dc1-evpn-leaf1 ip -d link show vxlan10100
docker exec clab-dc1-evpn-leaf1 bridge fdb show dev vxlan10100
```
**Ce qu'on montre :** control plane MP-BGP EVPN, data plane VXLAN, single VNI.

---

## 3. Connectivité des services (L2 étendu sur tout le fabric)

```bash
# web1 (leaf1) -> web2 (leaf2) -> dns1 : meme subnet 172.20.1.0/24, traverse le VXLAN
docker exec clab-dc1-evpn-web1 ping -c3 172.20.1.11
docker exec clab-dc1-evpn-web1 ping -c3 172.20.1.20

# Page web servie (HA derriere HAProxy cote host)
docker exec clab-dc1-evpn-web1 wget -qO- http://172.20.1.11

# Depuis la VM (via la gateway veth-host 172.20.1.254)
ping -c3 172.20.1.10
curl -s http://172.20.1.10
```
**Ce qu'on montre :** deux conteneurs sur des leafs differents communiquent en L2 pur via VXLAN.

---

## 4. DNS (Unbound) + Haute disponibilité

```bash
# Resolution via dns1 puis dns2
docker exec clab-dc1-evpn-web1 nslookup web2.dc1.local 172.20.1.20
docker exec clab-dc1-evpn-web1 nslookup web2.dc1.local 172.20.1.21

# Test de bascule automatique (coupe dns1, dns2 prend le relais)
sudo bash dc1/scripts/test-dns-ha.sh
```
**Ce qu'on montre :** deux resolveurs, bascule transparente si l'un tombe.

---

## 5. Haute disponibilité de l'infra IP (test du prof : spine down)

```bash
# Avant : ECMP sur les deux spines
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip route 172.16.255.13"

# Couper un spine
docker stop clab-dc1-evpn-spine1

# La connectivite continue via spine2 (le ping ne tombe pas)
docker exec clab-dc1-evpn-web1 ping -c5 172.20.1.20

# Les sessions BGP basculent, le VNI reste up
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn vni"

# Remettre le spine
docker start clab-dc1-evpn-spine1
```
**Ce qu'on montre :** convergence et redondance leaf-spine (perte d'un spine = pas de coupure).

---

## 6. SNMP sur les leafs (trafic + routes)

```bash
# (si pas deja fait) activer snmpd + AgentX FRR
sudo bash dc1/scripts/enable-snmp.sh

# Interfaces du leaf en SNMP (IF-MIB) — port 10161
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.2.2.1.2

# Compteurs de trafic 64 bits (ce qui monte avec le trafic)
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.31.1.1.1.6

# Etat des sessions BGP via SNMP (BGP4-MIB, "voir les routes en SNMP")
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.15.3.1.2
```
**Ce qu'on montre :** supervision SNMP des equipements, interfaces ET BGP.

---

## 7. Télémétrie : Prometheus + Grafana

```bash
# Verif automatique de toute la chaine
bash dc1/scripts/check-telemetry.sh

# Cibles Prometheus (snmp-fabric-if / -bgp doivent passer UP)
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | grep -E '"job"|"health"'
```
Puis dans le navigateur : **Grafana** `http://<IP_VM>:3000` (admin / DevCloud2025!)
→ dashboard **DC1 - Réseau & Services** : sessions BGP, débit par interface, erreurs, CPU/mém.

**Ce qu'on montre :** stack d'observabilite complete SNMP -> Prometheus -> Grafana.

---

## 8. Génération de trafic (pour voir les courbes bouger)

```bash
sudo bash dc1/scripts/iperf-test.sh 20
```
iperf3 entre leaf1 et leaf3 a travers le VXLAN. Pendant ce temps, le débit
apparait dans Grafana et les compteurs SNMP augmentent.

**Ce qu'on montre :** trafic reel a travers l'overlay + visualisation temps reel.

---

## 9. Multi-vendor & interconnexion (boitiers physiques)

```bash
# iBGP Catalyst <-> Mikrotik etabli
#   (sur le Catalyst)
show ip bgp summary
#   (sur le Mikrotik)
/routing/bgp/session/print

# Le Catalyst annonce 172.20.1.0/24 vers la salle (eBGP)
show ip bgp neighbors advertised-routes

# Joignabilite depuis un autre groupe vers nos services (a faire avec un binome de classe)
#   depuis leur reseau : ping/curl vers 172.20.1.10
```
**Ce qu'on montre :** FRR (DC1) + Arista cEOS (DC2 binome) + Catalyst + Mikrotik, BGP inter-groupes.

---

## 10. Sauvegardes & source de vérité

```bash
# Oxidized sauvegarde les configs vers Git (backup automatique)
docker logs dc1-oxidized 2>&1 | tail -20

# Nautobot peuple via API Python
python3 dc1/scripts/populate-nautobot.py
# puis http://172.20.1.70:8080
```

---

## Récapitulatif checklist BBP

| Item | Commande de preuve | Section |
|---|---|---|
| Connectivité intra | ping web1->web2 | 3 |
| Image FRR custom | docker build | 0 |
| HA (spine down) | docker stop spine1 + ping | 5 |
| Stack observabilité | check-telemetry.sh + Grafana | 7 |
| DNS | nslookup + test-dns-ha.sh | 4 |
| Web | curl web1/web2 | 3 |
| Oxidized -> Git | docker logs dc1-oxidized | 10 |
| Nautobot | populate-nautobot.py | 10 |
| SNMP / télémétrie | snmpwalk + Grafana | 6,7 |
| Trafic / charge | iperf-test.sh | 8 |

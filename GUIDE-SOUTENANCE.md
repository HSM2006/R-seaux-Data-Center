# Guide de validation / soutenance — SAE DevCloud 4D01 (DC1)

Commandes de preuve pour chaque brique du projet, à lancer depuis la VM
Debian (`~/R-seaux-Data-Center`). Conteneurs nommés `clab-dc1-evpn-<noeud>`.

IP de management fixes (Containerlab) :
leaf1=172.20.20.11, leaf2=.12, leaf3=.13, spine1=.101, spine2=.102.
SNMP écoute sur le port **10161** (le 161 est bloqué dans le netns containerlab).
Grafana : `http://10.202.0.60:3000` (admin / DevCloud2025!)
Prometheus : `http://10.202.0.60:9090`

---

## 0. Déploiement complet (point de départ, ou si reboot)

```bash
cd ~/R-seaux-Data-Center
docker build -t frrouting/frr:latest dc1/frr-custom/
sudo bash dc1/scripts/deploy.sh
( cd dc1/services/observability && docker compose up -d )
```

`docker ps` doit montrer 11 conteneurs clab + 4 conteneurs d'observabilité.
Au boot, docker-start.sh démarre automatiquement : FRR (bgpd -M snmp), snmpd
sur le port 10161, et l'AgentX (socket /var/agentx/master en 0777).

---

## 1. Underlay BGP numéroté (iBGP single-AS + Route Reflectors)

```bash
# Sessions iBGP — toutes doivent afficher "Established" (pas Connect/Active)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"

# Loopbacks apprises via BGP (172.16.255.1, .2, .11, .12, .13)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip route bgp"

# Côté spine — Route Reflector avec 3 clients
docker exec clab-dc1-evpn-spine1 vtysh -c "show ip bgp summary"

# Preuve "numbered" : IPs /31 explicites sur les liens
docker exec clab-dc1-evpn-leaf1 vtysh -c "show run" | grep -A2 "interface eth"
```

**Ce qu'on montre** : AS 65000 unique, IPs explicites sur chaque lien (numbered),
spines = Route Reflectors iBGP, full mesh leaf-spine.

---

## 2. Overlay EVPN / VXLAN (VNI 10100)

```bash
# VNI 10100 actif, 2 VTEP distants vus par chaque leaf
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn vni"

# Routes EVPN : type-2 (MAC/IP) + type-3 (VTEP du VNI)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show bgp l2vpn evpn"

# MAC distantes apprises par BGP (pas par flooding)
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn mac vni 10100"

# Côté kernel : bridge + device VXLAN
docker exec clab-dc1-evpn-leaf1 ip -d link show vxlan10100
docker exec clab-dc1-evpn-leaf1 bridge fdb show dev vxlan10100
```

**Ce qu'on montre** : control plane MP-BGP EVPN, data plane VXLAN, single VNI L2.

---

## 3. Connectivité des services (L2 étendu via VXLAN)

```bash
# web1 (leaf1) -> web2 (leaf2) : même subnet, traverse le VXLAN
docker exec clab-dc1-evpn-web1 ping -c3 172.20.1.11

# web1 (leaf1) -> dns1 (leaf1, même leaf)
docker exec clab-dc1-evpn-web1 ping -c3 172.20.1.20

# Page web servie
docker exec clab-dc1-evpn-web1 wget -qO- http://172.20.1.11

# Depuis la VM (via gateway veth-host 172.20.1.254)
ping -c3 172.20.1.10
curl -s http://172.20.1.10
```

**Ce qu'on montre** : conteneurs sur des leafs différents communiquent en L2 pur
via VXLAN. Les services web répondent.

---

## 4. DNS Unbound + Haute disponibilité

```bash
# Résolution via dns1
docker exec clab-dc1-evpn-web1 nslookup web2.dc1.local 172.20.1.20

# Résolution via dns2
docker exec clab-dc1-evpn-web1 nslookup web2.dc1.local 172.20.1.21

# Test de bascule automatique (coupe dns1, dns2 prend le relais)
sudo bash dc1/scripts/test-dns-ha.sh
```

**Ce qu'on montre** : deux résolveurs Unbound, bascule transparente.

---

## 5. Haute disponibilité IP (spine down — test du prof)

```bash
# Avant : routes via les deux spines
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip route 172.16.255.13"

# Couper spine1
docker stop clab-dc1-evpn-spine1

# La connectivité continue via spine2
docker exec clab-dc1-evpn-web1 ping -c5 172.20.1.12

# BGP bascule, VNI reste up
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"
docker exec clab-dc1-evpn-leaf1 vtysh -c "show evpn vni"

# Remettre le spine
docker start clab-dc1-evpn-spine1
sleep 15
docker exec clab-dc1-evpn-leaf1 vtysh -c "show ip bgp summary"
```

**Ce qu'on montre** : convergence, redondance leaf-spine, pas de coupure.

---

## 6. SNMP sur les leafs (trafic + routes en SNMP)

```bash
# Interfaces du leaf1 (IF-MIB) — port 10161
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.2.2.1.2

# Compteurs de trafic 64 bits
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.31.1.1.1.6

# Sessions BGP via SNMP (BGP4-MIB, 6 = established)
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.15.3.1.2

# AS distant des peers
snmpwalk -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.15.3.1.9

# sysLocation (prouve que c'est bien notre conf)
snmpget -v2c -c public 172.20.20.11:10161 .1.3.6.1.2.1.1.6.0
```

**Ce qu'on montre** : supervision SNMP des équipements réseau, interfaces ET
état BGP. C'est le "voir les routes en SNMP" demandé par le prof.

---

## 7. Télémétrie : Prometheus + Grafana

```bash
# Vérification automatique de toute la chaîne
bash dc1/scripts/check-telemetry.sh
```

Résultat attendu :
- SNMP direct : 5/5 OK (IF-MIB + BGP4-MIB)
- snmp_exporter : OK
- node_exporter : OK
- Cibles Prometheus : snmp-fabric-if 5/5 UP, snmp-fabric-bgp UP

Puis dans le navigateur : **Grafana** `http://10.202.0.60:3000`
→ dashboard **DC1 - Réseau & Services** (dossier DC1 - SAE DevCloud)

Panels visibles :
- **Sessions BGP établies** (compteur vert)
- **État des peers BGP** par routeur (courbe, 6 = established)
- **Débit ENTRANT/SORTANT** par interface en bits/s (courbes temps réel)
- **Erreurs interfaces**
- **35 interfaces UP**
- **CPU et mémoire hôte** (section dépliable)

---

## 8. Génération de trafic (voir les courbes bouger dans Grafana)

```bash
sudo bash dc1/scripts/iperf-test.sh 30
```

iperf3 entre leaf1 et leaf3 à travers le VXLAN (2.3 Gbps TCP, 0% perte UDP).
Pendant que ça tourne, rafraîchir le dashboard Grafana — le pic de débit
apparaît en temps réel sur les interfaces des leafs.

**Ce qu'on montre** : trafic réel à travers l'overlay + visualisation temps réel.

---

## 9. Multi-vendor & interconnexion (boîtiers physiques)

```bash
# iBGP Catalyst <-> Mikrotik
#   (sur le Catalyst)
show ip bgp summary
show ip bgp neighbors advertised-routes

#   (sur le Mikrotik)
/routing/bgp/session/print

# Joignabilité depuis un autre groupe
#   depuis leur réseau : ping / curl vers 172.20.1.10
```

**Ce qu'on montre** : FRR (DC1) + Arista cEOS (DC2 binôme) + Catalyst + Mikrotik.

---

## 10. Sauvegardes & source de vérité

```bash
# Oxidized (backup automatique des configs vers Git)
docker logs dc1-oxidized 2>&1 | tail -20

# Nautobot (source de vérité, peuplée via API)
python3 dc1/scripts/populate-nautobot.py
# puis http://172.20.1.70:8080

# Historique Git (commits progressifs individuels)
git log --oneline --author=Houssam | head -20
```

---

## 11. Image FRR custom (Dockerfile)

```bash
# Montrer le Dockerfile et ce qu'il inclut
cat dc1/frr-custom/Dockerfile

# Montrer le script de démarrage (SNMP + AgentX automatiques)
cat dc1/frr-custom/docker-start.sh
```

**Ce qu'on montre** : image construite nous-mêmes, pas un produit tout fait.
Inclut FRR + snmpd + iperf3 + frr-snmp. Le script de démarrage gère tout
(ip_forward, snmpd sur 10161, AgentX, mgmtd, zebra, bgpd -M snmp, vtysh -b).

---

## Récapitulatif checklist BBP

| Item checklist | Commande de preuve | Section |
|---|---|---|
| Kanban | GitHub Projects / board du repo | — |
| Connectivité intra-groupe | `ping web1→web2`, `curl web1` | 3 |
| Connectivité inter-groupe | ping depuis un autre groupe | 9 |
| Image FRR custom buildée | `docker build` + `cat Dockerfile` | 0, 11 |
| HA spine down + convergence | `docker stop spine1` + ping | 5 |
| VPN WireGuard | (si déployé) | — |
| Stack observabilité/monitoring | `check-telemetry.sh` + Grafana | 7 |
| DNS | `nslookup` + `test-dns-ha.sh` | 4 |
| Web | `curl` web1/web2/web3 | 3 |
| Uptime-Kuma | (si déployé : `http://172.20.1.50:3001`) | — |
| Oxidized → Git | `docker logs dc1-oxidized` | 10 |
| Nautobot | `populate-nautobot.py` + UI web | 10 |
| LDAP / Samba AD | `docker exec clab-dc1-evpn-samba` | 3 |
| SNMP / télémétrie | `snmpwalk` + Grafana | 6, 7 |
| Trafic / test de charge | `iperf-test.sh` | 8 |

---

## Séquence de démo recommandée (15-20 min)

1. Montrer `deploy.sh` qui orchestre tout → fabric up, BGP converge (section 0)
2. `show ip bgp summary` + `show evpn vni` → underlay + overlay (sections 1-2)
3. Ping inter-leaf + `curl` web → connectivité L2 étendue (section 3)
4. `docker stop spine1` → HA, ping continue → `docker start spine1` (section 5)
5. `snmpwalk` interfaces + BGP4-MIB → "voir les routes en SNMP" (section 6)
6. Ouvrir Grafana → montrer le dashboard avec les sessions BGP (section 7)
7. Lancer `iperf-test.sh 30` → voir le pic de débit dans Grafana en direct (section 8)
8. `test-dns-ha.sh` → DNS haute dispo (section 4)
9. Montrer le Dockerfile + docker-start.sh → image custom (section 11)
10. Git log → commits progressifs (section 10)

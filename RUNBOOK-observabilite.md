# RUNBOOK — Mise à jour observabilité / DNS / SNMP (juin 2026)

Ce qui a été ajouté/corrigé dans ce lot, et comment le déployer + tester sur la VM.
**Rien du fabric qui marche n'a été touché** (underlay BGP numéroté, EVPN/VXLAN,
setup-vtep, deploy.sh, configs FRR, services web, samba : intacts).

## Résumé des changements

| Domaine | Fichier(s) | Quoi |
|---|---|---|
| **DNS (corrigé)** | `services/unbound/unbound.conf` | conf durcie container (`username:""`/`chroot:""`) — corrige le "unbound démarre puis meurt" |
| **DNS (corrigé)** | `containerlab/topology.clab.yml` (dns1/dns2) | unbound en boucle de supervision : survit au crash ET au `docker restart` |
| **SNMP leafs** | `services/snmp/snmpd.conf`, `scripts/enable-snmp.sh` | snmpd (IF-MIB) + AgentX FRR (BGP4-MIB) = voir trafic ET routes en SNMP |
| **Télémétrie** | `services/observability/snmp-exporter/snmp.yml` | modules if_mib + bgp pour snmp_exporter |
| **Télémétrie** | `services/observability/prometheus/prometheus.yml` | jobs SNMP leafs/spines, node, frr, Catalyst, services |
| **Télémétrie** | `services/observability/docker-compose.yml` | + snmp_exporter, + node_exporter, host networking, provisioning Grafana |
| **Grafana** | `services/observability/grafana/...` | datasource + dashboard "DC1 - Réseau & Services" auto-chargés |
| **Tests** | `scripts/iperf-test.sh`, `scripts/test-dns-ha.sh`, `scripts/check-telemetry.sh` | génération trafic, bascule DNS, vérif chaîne télémétrie |
| **Image** | `frr-custom/Dockerfile` | snmpd + iperf3 + frr-snmp (best-effort) dans l'image |
| **Docs** | `docs/observabilite.md`, `docs/numbered-underlay.md`, `docs/bum-evpn.md` | explications + commandes |

## 0. Récupérer le lot sur la VM

```bash
cd ~/R-seaux-Data-Center      # ton clone sur la VM
git pull
```

## 1. Reconstruire l'image FRR (elle contient maintenant snmpd + iperf3)

```bash
docker build -t frrouting/frr:latest 'DC1 - Houssam/frr-custom/'
```
> Si le build échoue sur `frr-snmp`, ce n'est pas bloquant : il est en best-effort,
> l'image se construit quand même (IF-MIB via snmpd reste dispo).

## 2. Redéployer le fabric (DNS corrigé inclus)

```bash
sudo bash 'DC1 - Houssam/scripts/deploy.sh'
```

Vérifier le DNS tout de suite :

```bash
# unbound tourne sur dns1 et dns2 ?
docker exec clab-dc1-evpn-dns1 pgrep unbound && echo "dns1 OK"
docker exec clab-dc1-evpn-dns2 pgrep unbound && echo "dns2 OK"
# résolution depuis web1
docker exec clab-dc1-evpn-web1 nslookup web2.dc1.local 172.20.1.20
```

Test de bascule HA DNS (le test du prof) :

```bash
sudo bash 'DC1 - Houssam/scripts/test-dns-ha.sh'
```

## 3. Activer SNMP sur les leafs/spines

```bash
sudo bash 'DC1 - Houssam/scripts/enable-snmp.sh'
```

Vérifier que les leafs répondent en SNMP :

```bash
# Interfaces de leaf1
snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.2.2.1.2
# Sessions BGP de leaf1 (6 = established)
snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.15.3.1.2
```

## 4. Lancer la stack d'observabilité

```bash
cd 'DC1 - Houssam/services/observability'
docker compose up -d
cd ../../..
```

Grafana : `http://<IP_VM>:3000` (admin / DevCloud2025!)
→ dashboard **DC1 - Réseau & Services** (dossier *DC1 - SAE DevCloud*).
Prometheus cibles : `http://<IP_VM>:9090/targets`

(Optionnel, métriques FRR natives en plus : `sudo bash 'DC1 - Houssam/scripts/enable-frr-exporter.sh'`)

## 5. Générer du trafic et le voir monter

```bash
sudo bash 'DC1 - Houssam/scripts/iperf-test.sh' 20
```
→ débit affiché en CLI, compteurs SNMP qui montent, et courbe de débit dans Grafana.

## 6. Vérifier toute la chaîne d'un coup

```bash
bash 'DC1 - Houssam/scripts/check-telemetry.sh'
```

## Ordre court (copier-coller)

```bash
cd ~/R-seaux-Data-Center && git pull
docker build -t frrouting/frr:latest 'DC1 - Houssam/frr-custom/'
sudo bash 'DC1 - Houssam/scripts/deploy.sh'
sudo bash 'DC1 - Houssam/scripts/enable-snmp.sh'
( cd 'DC1 - Houssam/services/observability' && docker compose up -d )
bash 'DC1 - Houssam/scripts/check-telemetry.sh'
sudo bash 'DC1 - Houssam/scripts/iperf-test.sh' 20
```

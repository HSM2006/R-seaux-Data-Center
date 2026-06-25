# Observabilité / Télémétrie DC1

## Principe

Le prof veut pouvoir "voir les routes" et le trafic des leafs en SNMP, et avoir
une vraie télémétrie. Comme les leafs tournent sous **FRR** (qui n'a PAS de
serveur gNMI), le bon chemin de télémétrie pour DC1 c'est **SNMP**, pas gNMI.
(gNMIc reste prévu pour le DC2 du binôme en Arista cEOS, qui parle gNMI nativement.)

```
  leafs/spines FRR ──SNMP(161)──> snmp_exporter ──> Prometheus ──> Grafana
       │                            (IF-MIB +              (TSDB)     (dashboards)
       │                             BGP4-MIB)
       └── snmpd (compteurs interfaces) + AgentX (FRR -M snmp => BGP/routes)

  hôte VM ──> node_exporter ──> Prometheus
  services web ──> Uptime-Kuma (up/down) ──> Prometheus
```

Deux choses passent par SNMP :
- **IF-MIB** (compteurs d'octets par interface) : c'est ce qui monte quand on
  génère du trafic avec iperf. Sert aux courbes de débit dans Grafana.
- **BGP4-MIB** (via l'AgentX de FRR, daemons lancés avec `-M snmp`) : état des
  sessions BGP et des routes. C'est le "voir les routes en SNMP" demandé.

## Mise en route (dans l'ordre)

```bash
# 1. Le fabric doit déjà tourner (deploy.sh)
sudo bash 'DC1 - Houssam/scripts/deploy.sh'

# 2. Activer SNMP sur les leafs/spines (snmpd + AgentX FRR)
sudo bash 'DC1 - Houssam/scripts/enable-snmp.sh'

# 3. Lancer la stack d'observabilité (Prometheus + Grafana + exporters)
cd 'DC1 - Houssam/services/observability' && docker compose up -d && cd -

# 4. (optionnel) métriques FRR natives en plus du SNMP
sudo bash 'DC1 - Houssam/scripts/enable-frr-exporter.sh'

# 5. Vérifier toute la chaîne
bash 'DC1 - Houssam/scripts/check-telemetry.sh'
```

Grafana : `http://<IP_VM>:3000` (admin / DevCloud2025!).
Dashboard auto-chargé : **DC1 - Réseau & Services** (dossier *DC1 - SAE DevCloud*).

## Démo trafic (à montrer au prof)

```bash
# Génère du trafic web1 -> web3 à travers l'overlay VXLAN
sudo bash 'DC1 - Houssam/scripts/iperf-test.sh' 20
```

Pendant ce temps, dans Grafana, les courbes "Débit par interface" décollent, et
en SNMP direct :

```bash
# Compteur d'octets sortie de l'interface services de leaf1
snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.31.1.1.1.10
# Etat des sessions BGP de leaf1 (6 = established)
snmpwalk -v2c -c public 172.20.20.11 .1.3.6.1.2.1.15.3.1.2
```

## Fichiers

| Fichier | Rôle |
|---|---|
| `services/snmp/snmpd.conf` | conf snmpd des leafs (IF-MIB + AgentX) |
| `scripts/enable-snmp.sh` | active snmpd + AgentX FRR sur chaque routeur |
| `services/observability/snmp-exporter/snmp.yml` | modules if_mib + bgp |
| `services/observability/prometheus/prometheus.yml` | jobs SNMP, node, frr, services |
| `services/observability/grafana/provisioning/` | datasource + provider dashboards |
| `services/observability/grafana/dashboards/dc1-network.json` | le dashboard |
| `scripts/iperf-test.sh` | génère du trafic pour les courbes |
| `scripts/check-telemetry.sh` | vérifie SNMP + exporters + cibles Prometheus |

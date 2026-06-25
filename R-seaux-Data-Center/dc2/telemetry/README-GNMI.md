# 🌐 gNMI Telemetry Stack pour SAE DevCloud 4D01

## 📋 Vue d'ensemble

Cette solution implémente une **collecte de télémétrie temps réel** via **gNMI (gRPC Network Management Interface)** pour monitorer l'infrastructure DC2.

### Architecture du flux

```
┌─────────────────────────────────────────────────────────────┐
│                    Arista cEOS Routers                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  spine1  │  │  spine2  │  │  leaf1   │  │  leaf3   │   │
│  │ :6030    │  │ :6030    │  │ :6030    │  │ :6030    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
└───────┼─────────────┼─────────────┼─────────────┼──────────┘
        │ gNMI        │ gNMI        │ gNMI        │ gNMI
        └─────────────┴─────────────┴─────────────┘
                      │
        ┌─────────────▼────────────┐
        │   TELEGRAF (gNMI Plugin)  │
        │   - BGP metrics           │
        │   - Route counts          │
        │   - Interface stats       │
        │   :9273 /metrics          │
        └─────────────┬────────────┘
                      │ Prometheus format
        ┌─────────────▼────────────┐
        │   PROMETHEUS              │
        │   - Time-series DB        │
        │   - Scrape Telegraf       │
        │   :9090                   │
        └─────────────┬────────────┘
                      │ HTTP API
        ┌─────────────▼────────────┐
        │   GRAFANA                 │
        │   - Dashboards            │
        │   - Visualizations        │
        │   :3000                   │
        └───────────────────────────┘
```

---

## 🚀 Installation & Déploiement

### Prérequis

- Docker & Docker Compose
- Containerlab avec DC2 déployé
- Arista cEOS avec gNMI activé (port 6030)
- Linux/macOS

### Étape 1 : Préparation des fichiers

```bash
mkdir -p ~/telemetry/grafana-provisioning/datasources
cd ~/telemetry

# Copier tous les fichiers fournis
cp docker-compose-telemetry.yml telegraf.conf prometheus.yml ./
cp grafana-datasources.yml grafana-provisioning/datasources/prometheus.yml
cp grafana-dashboard-dc2.json ./
```

### Étape 2 : Vérifier gNMI sur les routeurs

```bash
# Pour chaque routeur Arista
docker exec spine1 Cli -c "show management api gnmi status"
```

Output attendu :
```
Management API gNMI enabled, running on port 6030
```

Si **désactivé**, activer :
```bash
docker exec spine1 Cli << EOF
configure
management api gnmi
transport grpc default
exit
EOF
```

### Étape 3 : Lancer le stack Telemetry

```bash
docker-compose -f docker-compose-telemetry.yml up -d

# Vérifier le statut
docker-compose -f docker-compose-telemetry.yml ps
```

Expected output :
```
NAME         STATUS
telegraf     Up X minutes
prometheus   Up X minutes
grafana      Up X minutes
```

### Étape 4 : Vérifier la connectivité

```bash
# Lancer le test
python3 test-gnmi.py
```

Output attendu :
```
✅ spine1:     ✅ OK
✅ spine2:     ✅ OK
✅ leaf1:      ✅ OK
✅ leaf2:      ✅ OK
✅ leaf3:      ✅ OK

✅ All tests passed! gNMI is ready.
```

### Étape 5 : Importer le Dashboard

1. Ouvrir Grafana : **http://localhost:3000**
2. Identifiants : **admin / admin**
3. Menu **Dashboards** → **Import**
4. Uploader `grafana-dashboard-dc2.json`
5. Sélectionner datasource **Prometheus**
6. **Import** ✅

---

## 📊 Dashboards & Metrics

### Panels disponibles

| Panel | Métrique | Utilité |
|-------|----------|---------|
| **BGP Sessions Established** | `gnmi_bgp_neighbors{state=Established}` | Santé BGP |
| **BGP Sessions Count** | `count(gnmi_bgp_neighbors)` | Total sessions |
| **Route Count Evolution** | `gnmi_route_count` | Croissance routing table |
| **Bandwidth In/Out** | `rate(gnmi_interface_octets[1m])` | Débit réseau |
| **BGP Neighbors Table** | Details par neighbor | Debug BGP |

### Queries Prometheus avancées

```promql
# Sessions BGP par routeur
gnmi_bgp_neighbors{state="Established"} group by(instance)

# Routes IPv4 vs IPv6
gnmi_route_count{afi="IPV4"}
gnmi_route_count{afi="IPV6"}

# Interfaces avec erreurs
gnmi_interface_counters_in_errors > 0

# Débit moyen dernière heure
avg_over_time(gnmi_interface_bytes_in[1h])

# Alerte : Perte de session BGP
rate(gnmi_bgp_neighbors{state="Down"}[5m]) > 0
```

---

## 🔧 Configurations particulières

### Adapter pour DC1 (FRR)

Si tu veux monitorer aussi DC1 avec FRR, ajouter dans `telegraf.conf` :

```ini
[[inputs.gnmi]]
  addresses = ["catalyst:6030"]  # Border router Cisco
  username = "admin"
  password = "admin"
  insecure = true
```

### Changer l'intervalle de scrape

Éditer `telegraf.conf` :
```ini
[agent]
  interval = "15s"   # 15 secondes au lieu de 30
```

Redémarrer :
```bash
docker-compose -f docker-compose-telemetry.yml restart telegraf
```

### Ajouter des paths gNMI customisés

Dans `telegraf.conf`, sous la section `[[inputs.gnmi]]` du routeur :

```ini
[[inputs.gnmi.subscription]]
  name = "vxlan_stats"
  origin = "openconfig"
  path = "/interfaces/interface[name=Vxlan1]/state"
  subscription_mode = "target_defined"
  sample_interval = "30000000000"
```

---

## 📈 Pour la Présentation SAE

### Éléments à montrer

1. **Architecture gNMI**
   - Diagramme du flux (fourni ci-dessus)
   - Avantages vs. SNMP classique

2. **Dashboard Grafana en live**
   - BGP sessions chart
   - Evolution des routes
   - Bandwidth utilization

3. **Métriques clés**
   - Nombre de sessions BGP
   - Nombre de routes apprises
   - Débit entrant/sortant par interface

4. **Demo : Failover**
   - Arrêter une session BGP
   - Observer la chute immédiate sur le dashboard
   - Relancer et voir la récupération

### Screenshots pour slides

```bash
# Exporter un dashboard en PNG (Grafana Pro)
curl -L "http://localhost:3000/api/dashboards/uid/dc2-gnmi?panelId=2&from=now-1h&to=now" \
  -o dashboard-export.png
```

---

## 🐛 Troubleshooting

### Telegraf n'a pas de données

**Symptôme :** Les panels Grafana sont vides

**Solution :**
```bash
# Vérifier les logs
docker logs -f telegraf

# Tester la connectivité manuelle
docker exec telegraf bash -c "echo 'test' | nc -z spine1 6030"
```

### Prometheus ne trouve pas Telegraf

**Symptôme :** "No data" dans les graphs

**Solution :**
```bash
# Vérifier l'endpoint Telegraf
curl http://localhost:9273/metrics | head -20

# Vérifier la config Prometheus
curl http://localhost:9090/api/v1/targets
```

### gNMI connection timeout

**Symptôme :** Connection refused on port 6030

**Solution :**
```bash
# Vérifier que gNMI écoute
docker exec spine1 netstat -tlnp | grep 6030

# Relancer gNMI
docker exec spine1 Cli << EOF
configure
management api gnmi
transport grpc default
exit
EOF
```

---

## 📝 Fichiers fournis

| Fichier | Rôle |
|---------|------|
| `docker-compose-telemetry.yml` | Orchestration des services |
| `telegraf.conf` | Config collecteur gNMI |
| `prometheus.yml` | Config stockage metrics |
| `grafana-datasources.yml` | Connexion Prometheus |
| `grafana-dashboard-dc2.json` | Dashboard prédéfini |
| `test-gnmi.py` | Script de validation |
| `GUIDE-GNMI-SETUP.md` | Documentation complète |

---

## 🎯 Checklist SAE

- [ ] Stack déployé et running
- [ ] Tous les routeurs envoient des metrics (vérifier `docker logs telegraf`)
- [ ] Prometheus scrape les données (`curl http://localhost:9090/api/v1/query?query=up`)
- [ ] Grafana affiche au moins 30 min d'historique
- [ ] Dashboard importé et fonctionnel
- [ ] Test gNMI réussi (`python3 test-gnmi.py`)
- [ ] Screenshots pour présentation
- [ ] Demo live préparée

---

## 💡 Optimisations futures

- Ajouter AlertManager pour notifications Slack
- Implémenter custom alerts (BGP down, routes loss)
- Exporter metrics vers InfluxDB pour plus long terme
- Créer dashboards par couche (leaf, spine, services)

---

**Support SAE :** Contacte le prof si besoin d'aide sur l'intégration gNMI ! 🚀

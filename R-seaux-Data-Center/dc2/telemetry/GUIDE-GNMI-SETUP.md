# 📊 Guide Déploiement gNMI + Telegraf + Prometheus + Grafana

## 🚀 Démarrage rapide

### 1. Structure des fichiers

```
~/telemetry/
├── docker-compose-telemetry.yml
├── telegraf.conf
├── prometheus.yml
└── grafana-provisioning/
    └── datasources/
        └── prometheus.yml
```

### 2. Créer les répertoires

```bash
mkdir -p ~/telemetry/grafana-provisioning/datasources
cd ~/telemetry
```

### 3. Copier les fichiers

Place tous les fichiers `.yml` et `.conf` dans le répertoire `~/telemetry/`

### 4. Lancer le stack

```bash
docker-compose -f docker-compose-telemetry.yml up -d
```

Vérifier :
```bash
docker-compose -f docker-compose-telemetry.yml ps
```

---

## ⚙️ Configuration Arista cEOS

**Vérifier que gNMI est activé sur tes routeurs** :

```
spine1#configure
spine1(config)#management api gnmi
spine1(config-mgmt-api-gnmi)#transport grpc default
spine1(config-mgmt-api-grpc)#exit
spine1(config)#exit
spine1#show management api gnmi status
```

Vérifier le port **6030** (insecure) ou **6040** (secure) :
```
netstat -tlnp | grep 6030
```

---

## 🔌 Test de connectivité gNMI

### Test 1 : Depuis le host
```bash
# Installer gnmic (optionnel)
docker pull ghcr.io/openconfig/gnmic:latest

# Test de ping gNMI
docker run --rm --network host ghcr.io/openconfig/gnmic:latest \
  -a spine1:6030 \
  -u admin \
  -p admin \
  --insecure \
  capabilities
```

### Test 2 : Depuis Telegraf
```bash
# Logs de Telegraf
docker logs -f telegraf

# Vérifier les erreurs de connexion
docker exec telegraf telegraf --version
```

### Test 3 : Requête gNMI manuelle
```bash
grpcurl -plaintext \
  -d '{"type":0}' \
  spine1:6030 \
  gnmi.gNMI/Capabilities
```

---

## 📈 Accès aux outils

| Outil | URL | Identifiants |
|-------|-----|--------------|
| **Prometheus** | http://localhost:9090 | N/A |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Telegraf Metrics** | http://localhost:9273/metrics | N/A |

---

## 📊 Queries Prometheus utiles

### BGP Sessions (par routeur)
```promql
# Nombre de sessions BGP établies
gnmi_network_instances_network_instance_protocols_protocol_bgp_global_state_total_paths{device="spine1"}

# Sessions down
gnmi_network_instances_network_instance_protocols_protocol_bgp_neighbors{state="DOWN"}
```

### Routes
```promql
# Nombre total de routes
gnmi_network_instances_network_instance_state_route_count

# Routes IPv4
gnmi_network_instances_network_instance_state_route_count{afi="IPV4"}
```

### Interface Bandwidth
```promql
# Bytes in/out
rate(gnmi_interfaces_interface_state_counters_in_octets[1m])
rate(gnmi_interfaces_interface_state_counters_out_octets[1m])
```

---

## 🎯 Créer un Dashboard Grafana

### Étapes :
1. Ouvrir Grafana : http://localhost:3000
2. **Configuration** → **Data Sources** → Vérifier Prometheus OK ✅
3. **+** → **Create** → **Dashboard**
4. **Add panel**
5. Choisir requête Prometheus
6. Copier les queries du dessus

### Panel suggestions :
- ✅ BGP Session Status (Gauge)
- ✅ Route Count Evolution (Graph)
- ✅ Interface Bandwidth (Graph)
- ✅ BGP Neighbors Table
- ✅ Route Distribution (Pie chart)

---

## 🔧 Troubleshooting

### Telegraf ne collecte rien
```bash
# Vérifier config
docker exec telegraf telegraf -config /etc/telegraf/telegraf.conf -test

# Vérifier connectivité
docker exec telegraf ping spine1
```

### Erreur "connection refused"
```bash
# Vérifier que gNMI écoute
docker exec spine1 netstat -tlnp | grep 6030

# Relancer gNMI sur le routeur
docker exec spine1 Cli -c "configure"
docker exec spine1 Cli -c "management api gnmi"
docker exec spine1 Cli -c "transport grpc default"
```

### Prometheus ne scrape pas Telegraf
```bash
# Vérifier que Telegraf expose /metrics
curl http://localhost:9273/metrics | head -20
```

---

## 📝 Modifications usuelles

### Ajouter un nouveau routeur

Dans `telegraf.conf`, ajouter :
```ini
[[inputs.gnmi]]
  addresses = ["leaf4:6030"]
  username = "admin"
  password = "admin"
  insecure = true
  skip_verify = true
  
  [[inputs.gnmi.subscription]]
    name = "bgp_summary"
    origin = "openconfig"
    path = "/network-instances/network-instance[name=default]/protocols/protocol[identifier=BGP]/bgp/global/state"
    subscription_mode = "target_defined"
    sample_interval = "30000000000"
```

Puis redémarrer :
```bash
docker-compose -f docker-compose-telemetry.yml restart telegraf
```

### Changer l'intervalle de collection

```ini
[agent]
  interval = "15s"  # Au lieu de 30s
```

### Ajouter une alerte Prometheus

Créer `prometheus-rules.yml` :
```yaml
groups:
  - name: bgp
    rules:
      - alert: BGPSessionDown
        expr: gnmi_network_instances_network_instance_protocols_protocol_bgp_neighbors{state="DOWN"} > 0
        for: 5m
        annotations:
          summary: "BGP session DOWN on {{ $labels.device }}"
```

---

## ✅ Checklist SAE

- [ ] Stack gNMI/Telegraf/Prometheus/Grafana déployé
- [ ] Tous les routeurs collectent leurs métriques
- [ ] Dashboard Grafana avec :
  - [ ] BGP Sessions chart
  - [ ] Route count evolution
  - [ ] Bandwidth in/out par interface
  - [ ] BGP neighbors table
- [ ] Données sur 30 min minimum (pour demo)
- [ ] Screenshots pour présentation

---

## 💡 Pour la présentation

Montrer :
1. **Architecture gNMI** (Arista → Telegraf → Prometheus → Grafana)
2. **Métriques en temps réel** sur les spines/leafs
3. **Alertes** si une session BGP tombe
4. **Historique** de convergence après failover

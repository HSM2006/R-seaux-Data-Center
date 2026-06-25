#  Datacenter DC2 EVPN/VXLAN

## 📋 Vue d'ensemble

Projet de déploiement d'un **datacenter (DC2)** complet avec :
- Architecture **Leaf-Spine (Clos)** en EVPN/VXLAN
- **2 spines** (Route Reflectors, AS 65000)
- **3 leafs** (VXLAN VTEPs, AS 65000)
- Services : **Nginx, DNS (Unbound), Samba**
- Interconnexion avec DC1 via **tunnel DCI (VNI 1040)**
- **Telemetry gNMI** avec Telegraf + Prometheus + Grafana

---

## 🏗️ Architecture

### Topologie physique

```
┌─────────────────────────────────────────────────────────┐
│  Proxmox Hypervisor (Debian 13 VM)                      │
│                                                         │
│  ens19 (Physical NIC)                                   │
│    ↓                                                    │
│  br-dc2 (Bridge)  ← Containerlab topology             │
│    ↓                                                    │
│  ┌─────────────────────────────────────────────┐      │
│  │ Spine1 (cEOS)       Spine2 (cEOS)           │      │
│  │  172.16.255.1/32    172.16.255.2/32         │      │
│  │  AS 65000 RR        AS 65000 RR             │      │
│  └─────────────────────────────────────────────┘      │
│    │         │         │         │                     │
│  ┌─┴─┐     ┌─┴─┐     ┌─┴─┐     ┌─┴─┐                 │
│  Leaf1   Leaf2      Leaf3    (DC1 leaf3)              │
│  172.16  172.16    172.16    DCI tunnel               │
│  .255.14 .255.15   .255.16   VLAN 40/VNI 1040        │
│  (VTEP)  (VTEP)    (VTEP)                             │
│    │       │        │                                  │
│  ┌─┴──────┴────────┴─┐                                │
│  Services VLAN 200    │                                │
│  172.20.2.0/24        │                                │
│  ├─ web1    (.10)     │                                │
│  ├─ web2    (.11)     │                                │
│  ├─ web3    (.12)     │                                │
│  ├─ dns1    (.20)     │                                │
│  ├─ dns2    (.21)     │                                │
│  └─ samba   (.30)     │                                │
│                                                        │
│  Telemetry Stack:                                      │
│  ├─ Telegraf (gNMI client, :9273)                      │
│  ├─ Prometheus (:9090)                                 │
│  └─ Grafana (:3000)                                    │
└────────────────────────────────────────────────────────┘
```

### Protocoles de routage

| Protocole | Domaine | Description |
|-----------|---------|-------------|
| **BGP iBGP** | AS 65000 (Spine-Leaf) | Route Reflector (spine1/spine2) |
| **EVPN** | AF ipv4-unicast + evpn | VXLAN overlay, MAC learning |
| **VXLAN** | VLAN 200 → VNI 10200 | Services overlay |
| **DCI** | VLAN 40 → VNI 1040 | Tunnel vers DC1 leaf3 |

---

## 🚀 Déploiement

### Prérequis

- **Proxmox** hypervisor (7.x+)
- **Debian 13** VM avec :
  - Docker (Engine 20.10+)
  - Containerlab (0.50+)
  - 4+ cores CPU
  - 8+ GB RAM
  - 30 GB stockage

### 1️⃣ Préparer l'infrastructure Proxmox

```bash
# Créer une VM Debian 13
# - Bridge sur ens19 physique (pour le trafic DC2/DC1)
# - vNet0 : management (10.x.x.x)
# - vNet1 : ens19 bridged → br-dc2 Containerlab

# Depuis la VM Debian
sudo apt update && sudo apt install -y docker.io

# Télécharger Containerlab
curl https://containerlab.srlinux.dev/setup | bash -s -- -v 0.50.0

# Créer répertoires
mkdir -p ~/dc2-final-v4/DC2/{containerlab,telemetry}/{ceos,configs}
```

### 2️⃣ Déployer la topologie Containerlab

```bash
cd ~/dc2-final-v4/DC2/containerlab

# Copier topology.clab.yml et configs cEOS
# (voir fichiers configs dans le dépôt)

# Créer les bridges manquants
sudo ip link add br-catalyst type bridge && sudo ip link set br-catalyst up
sudo ip link add br-mikrotik type bridge && sudo ip link set br-mikrotik up

# Déployer
sudo clab deploy -t topology.clab.yml

# Vérifier
sudo clab inspect
```

### 3️⃣ Configurer iBGP & EVPN

Les configs sont dans `~/dc2-final-v4/DC2/containerlab/ceos/*.cfg` :

**Spine** (Route Reflector) :
```
router bgp 65000
  bgp cluster-id 172.16.255.1
  neighbor 172.16.255.14 remote-as 65000
  neighbor 172.16.255.15 remote-as 65000
  neighbor 172.16.255.16 remote-as 65000
  
  address-family evpn
    neighbor 172.16.255.14 activate
    neighbor 172.16.255.15 activate
    neighbor 172.16.255.16 activate
```

**Leaf** (VTEP) :
```
router bgp 65000
  neighbor 172.16.255.1 remote-as 65000
  neighbor 172.16.255.2 remote-as 65000
  
  address-family evpn
    neighbor 172.16.255.1 activate
    neighbor 172.16.255.2 activate
    neighbor 172.16.255.1 route-reflector-client
    neighbor 172.16.255.2 route-reflector-client
```

---

## 📊 Telemetry gNMI

### Configuration Spine1 (test)

```bash
docker exec clab-dc2-evpn-spine1 Cli << EOF
configure terminal
username admin privilege 15 secret admin123
management api gnmi
  transport grpc default
  no authorization
exit
exit
write memory
EOF
```

Vérifier :
```bash
docker exec clab-dc2-evpn-spine1 Cli -c "show management api gnmi"
```

Résultat attendu :
```
Transport: default
Enabled: yes
Server: running on port 6030
Authorization required: no
```

### Telegraf Configuration

Fichier : `~/dc2-final-v4/DC2/telemetry/telegraf-SIMPLE.conf`

```toml
[global_tags]
  datacenter = "dc2"
  environment = "lab"

[agent]
  interval = "30s"
  flush_interval = "10s"
  hostname = "telegraf"

[[inputs.gnmi]]
  addresses = [
    "clab-dc2-evpn-spine1:6030",
    "clab-dc2-evpn-spine2:6030",
    "clab-dc2-evpn-leaf1:6030",
    "clab-dc2-evpn-leaf2:6030",
    "clab-dc2-evpn-leaf3:6030"
  ]
  
  username = "admin"
  password = "admin123"
  
  subscriptions = [
    "bgp_summary",
    "bgp_neighbors",
    "routes",
    "interfaces"
  ]

[[outputs.prometheus_client]]
  listen = ":9273"
```

### Déployer le stack Telemetry

```bash
cd ~/dc2-final-v4/DC2/telemetry

# Lancer les containers
docker compose -f docker-compose-telemetry.yml up -d

# Vérifier Telegraf
sleep 10
docker logs telegraf | grep -E "Starting|Listening|Error"

# Accéder aux interfaces
# - Prometheus : http://localhost:9090
# - Grafana : http://localhost:3000 (admin/admin)
```

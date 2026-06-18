#!/bin/bash
# ============================================================
# check-telemetry.sh — Vérifie la chaîne d'observabilité
# SAE DevCloud 4D01 — Houssam
#
# Contrôle, depuis la VM : SNMP des leafs, snmp_exporter,
# node_exporter, et l'état des cibles Prometheus.
#
# Usage : bash dc1/scripts/check-telemetry.sh
# ============================================================

LEAFS_MGMT=("172.20.20.11" "172.20.20.12" "172.20.20.13" "172.20.20.101" "172.20.20.102")
PROM="http://localhost:9090"
SNMPEXP="http://localhost:9116"

ok()   { echo "  [OK]   $1"; }
ko()   { echo "  [KO]   $1"; }

echo "=== 1) SNMP direct sur les leafs/spines (IF-MIB) ==="
for ip in "${LEAFS_MGMT[@]}"; do
  if snmpget -v2c -c public -t 1 -r 1 "$ip" .1.3.6.1.2.1.1.6.0 >/dev/null 2>&1; then
    ifcount=$(snmpwalk -v2c -c public -t 1 "$ip" .1.3.6.1.2.1.2.2.1.2 2>/dev/null | wc -l)
    ok "$ip répond ($ifcount interfaces)"
  else
    ko "$ip ne répond pas en SNMP (lance enable-snmp.sh ?)"
  fi
done

echo ""
echo "=== 2) SNMP BGP4-MIB (voir les routes/peers) ==="
for ip in "${LEAFS_MGMT[@]}"; do
  peers=$(snmpwalk -v2c -c public -t 1 "$ip" .1.3.6.1.2.1.15.3.1.2 2>/dev/null | wc -l)
  [ "$peers" -gt 0 ] && ok "$ip : $peers peers BGP visibles" || ko "$ip : pas de BGP4-MIB (module FRR snmp absent ?)"
done

echo ""
echo "=== 3) snmp_exporter (passerelle) ==="
if curl -fsS "$SNMPEXP/snmp?target=172.20.20.11&module=if_mib&auth=public_v2" 2>/dev/null | grep -q ifHCInOctets; then
  ok "snmp_exporter répond et scrute leaf1"
else
  ko "snmp_exporter ne répond pas (docker compose up dans services/observability ?)"
fi

echo ""
echo "=== 4) node_exporter (hôte) ==="
curl -fsS http://localhost:9100/metrics 2>/dev/null | grep -q node_cpu_seconds_total && ok "node_exporter OK" || ko "node_exporter absent"

echo ""
echo "=== 5) Cibles Prometheus (up/down) ==="
if curl -fsS "$PROM/api/v1/targets" 2>/dev/null | grep -q '"health"'; then
  curl -fsS "$PROM/api/v1/targets" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  [{t[\"health\"].upper():5}] {t[\"labels\"].get(\"job\")} -> {t[\"scrapeUrl\"]}') for t in d['data']['activeTargets']]" 2>/dev/null \
    || echo "  (jq/python indispo pour le détail)"
else
  ko "Prometheus injoignable sur $PROM"
fi

echo ""
echo "============================================================"
echo " Grafana : http://<IP_VM>:3000  (admin / DevCloud2025!)"
echo " Dashboard : 'DC1 - Réseau & Services' (dossier DC1 - SAE DevCloud)"
echo "============================================================"

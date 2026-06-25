#!/bin/bash
# check-telemetry.sh — Verifie la chaine d'observabilite
# SAE DevCloud 4D01 — Houssam

SNMP_PORT=10161
LEAFS_MGMT=("172.20.20.11" "172.20.20.12" "172.20.20.13" "172.20.20.101" "172.20.20.102")
PROM="http://localhost:9090"

ok()   { echo "  [OK]   $1"; }
ko()   { echo "  [KO]   $1"; }

echo "=== 1) SNMP direct sur les leafs/spines (IF-MIB, port $SNMP_PORT) ==="
for ip in "${LEAFS_MGMT[@]}"; do
  if snmpget -v2c -c public -t 1 -r 1 "$ip:$SNMP_PORT" .1.3.6.1.2.1.1.6.0 >/dev/null 2>&1; then
    ifcount=$(snmpwalk -v2c -c public -t 1 "$ip:$SNMP_PORT" .1.3.6.1.2.1.2.2.1.2 2>/dev/null | wc -l)
    ok "$ip : $ifcount interfaces"
  else
    ko "$ip ne repond pas en SNMP sur port $SNMP_PORT"
  fi
done

echo ""
echo "=== 2) SNMP BGP4-MIB (peers/routes) ==="
for ip in "${LEAFS_MGMT[@]}"; do
  peers=$(snmpwalk -v2c -c public -t 1 "$ip:$SNMP_PORT" .1.3.6.1.2.1.15.3.1.2 2>/dev/null | wc -l)
  [ "$peers" -gt 0 ] && ok "$ip : $peers peers BGP" || ko "$ip : pas de BGP4-MIB"
done

echo ""
echo "=== 3) snmp_exporter ==="
if curl -fsS "http://localhost:9116/snmp?target=172.20.20.11:${SNMP_PORT}&module=if_mib&auth=public_v2" 2>/dev/null | grep -q ifHCInOctets; then
  ok "snmp_exporter -> leaf1 OK"
else
  ko "snmp_exporter ne repond pas"
fi

echo ""
echo "=== 4) node_exporter ==="
curl -fsS http://localhost:9100/metrics 2>/dev/null | grep -q node_cpu && ok "node_exporter OK" || ko "node_exporter absent"

echo ""
echo "=== 5) Cibles Prometheus ==="
if curl -fsS "$PROM/api/v1/targets" 2>/dev/null | grep -q '"health"'; then
  curl -fsS "$PROM/api/v1/targets" 2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  [{t[\"health\"].upper():5}] {t[\"labels\"].get(\"job\")} -> {t[\"scrapeUrl\"]}') for t in d['data']['activeTargets']]" 2>/dev/null
else
  ko "Prometheus injoignable"
fi

echo ""
echo "  Grafana : http://<IP_VM>:3000  (admin / DevCloud2025!)"
